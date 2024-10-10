//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private let storageManager = StorageManager.shared
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.title
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.title
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    // MARK: - Private Methods
    private func updateTasks() {
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
    }

    // MARK: - UITableViewDelegate
        override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] (_, _, completionHandler) in
                storageManager.delete(task)
                updateTasks()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completionHandler(true)
            }
            
            let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] (_, _, completionHandler) in
                showAlert(with: task) {
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                completionHandler(true)
            }
            
            let doneTitle = task.isComplete ? "Remove" : "Done"
            let doneAction = UIContextualAction(style: .normal, title: doneTitle) { [unowned self] (_, _, completionHandler) in
                storageManager.write {
                    task.isComplete.toggle()
                }
                tableView.beginUpdates()
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                updateTasks()
                
                let newSection = task.isComplete ? 1 : 0
                let newRow = (task.isComplete ? completedTasks : currentTasks).index(of: task)!
                let newIndexPath = IndexPath(row: newRow, section: newSection)
                
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            
                tableView.endUpdates()
                
                completionHandler(true)
            }
            
            editAction.backgroundColor = .orange
            doneAction.backgroundColor = task.isComplete ? .systemBlue : .systemGreen
            
            return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
        }
}

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let alertBuilder = AlertControllerBuilder(
            title: task != nil ? "Edit Task" : "New Task",
            message: "What do you want to do?"
        )
        
        alertBuilder
            .setTextField(withPlaceholder: "Task Title", andText: task?.title)
            .setTextField(withPlaceholder: "Note Title", andText: task?.note)
            .addAction(
                title: task != nil ? "Update Task" : "Save Task",
                style: .default
            ) { [unowned self] taskTitle, taskNote in
                if let task {
                    storageManager.write {
                        task.title = taskTitle
                        task.note = taskNote
                    }
                    completion?()
                } else {
                    createTask(withTitle: taskTitle, andNote: taskNote)
                }
            }
            .addAction(title: "Cancel", style: .destructive)
        
        let alertController = alertBuilder.build()
        present(alertController, animated: true)
    }
    
    private func createTask(withTitle title: String, andNote note: String) {
        storageManager.save(title, withNote: note, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}
