//
//  HTMLPresenterViewController.swift
//  XMLSimpleParser
//
//  Created by Miguel Angel Adan Roman on 20/5/18.
//  Copyright © 2018 Avantiic. All rights reserved.
//

import UIKit

class HTMLPresenterViewController: UITableViewController {
    
    var result: [HTMLEntity]?
    var selectedOption: String?
    var downloadedImages = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        if let fileName = selectedOption {
            let dataRequest = DataRequest()
            dataRequest.request(fileName: fileName, success: { (data) in
                DispatchQueue.global().async {
                    let parser = XMLSimpleParser(data: data)
                    parser.preserveTextEntities = true
                    parser.resultDelegate = self
                    parser.parse()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let htmlEntity = result?[indexPath.row], htmlEntity.type == .image {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCellId", for: indexPath) as! ImageTableViewCell
            if let url = URL(string: htmlEntity.content) {
                
                cell.customImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageUrl) in
                    
                    if let width = image?.size.width, let height = image?.size.height {
                        cell.aspectRatio = NSLayoutConstraint(
                            item: cell.customImageView,
                            attribute: .height,
                            relatedBy: .equal,
                            toItem: cell.customImageView,
                            attribute: .width,
                            multiplier: (height / width),
                            constant: 1
                        )
                        
                        cell.customImageView.addConstraint(cell.aspectRatio!)
                        
                        if !self.downloadedImages.contains(htmlEntity.content) {
                            self.downloadedImages.append(htmlEntity.content)
                            self.tableView.reloadData()
                        }
                    }
                })
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: indexPath)
        cell.textLabel?.text = result?[indexPath.row].content
        
        return cell
    }
}

extension HTMLPresenterViewController: XMLSimpleParserDelegate {
    func xmlParserDidFinishProcessingDocument(_ node: Node) {
        DispatchQueue.global().async {
            let entitiesGenerator = HTMLEntitiesGenerator()
            entitiesGenerator.generateHtmlEntityWith(node: node)
            self.result = entitiesGenerator.entities
            
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }
    
    func xmlParserDidFinishProcessingDocumentWithError(_ error: Error) {
        print(error.localizedDescription)
    }
}