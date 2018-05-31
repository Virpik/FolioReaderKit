//
//  File.swift
//  FolioReaderKit
//
//  Created by Virpik on 31/05/2018.
//

import Foundation

public class FRBooks {
    
    public private(set) var books: [FRBook] = []
    public var index: Int = 0
    
    public var book: FRBook {
        if self.index >= self.books.count {
            return FRBook()
        }
        
        return self.books[self.index]
    }
    
    public var pages: Int {
        return self.spineReferences.count
    }
    
    var spines: [FRSpine] {
        return self.books.map({ $0.spine })
    }
    
    var spineReferences: [Spine] {
        return self.spines.flatMap({ return $0.spineReferences })
    }
    
    public var page: Int = 0
    
    func append(book: FRBook) {
        self.books.append(book)
    }
    
    init() {
        
    }
}
