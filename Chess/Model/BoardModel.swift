//
//  BoardModel.swift
//  Chess
//
//  Created by Pavol Margitfalvi on 19/12/2017.
//  Copyright © 2017 Pavol Margitfalvi. All rights reserved.
//

import Foundation

enum BoardError: Error {
    
    case invalidMove
    
}

class BoardModel{
    
    var publicBoard: [[Piece?]] {
        get {
            return board
        }
    }
    
    // TODO: Optimize by letting the subarray be an optional as well, so if a row is empty it is skipped in loops
    private var board: [[Piece?]]
    var delegate: BoardModelDelegate?
    
    var turnOfColor = PieceColor.white
    
    init() {
        
        board = BoardModel.defaultBoard()
        
    }
    
    func movePiece(from oldPosition: (x: Int, y: Int), to newPosition: (x: Int, y: Int)) throws {
        
        if (moveAllowed(from: oldPosition, to: newPosition)) {
            
            // Responsible for alternating the player turns
            if turnOfColor == .black {
                turnOfColor = .white
            } else {
                turnOfColor = .black
            }
            
            // If the newPosition square is populated, we have to let the delegate know that a piece is about to be captured
            if board[newPosition.y][newPosition.x] != nil {
                
                delegate?.pieceCaptured(at: newPosition)
                
            }
            
            delegate?.pieceMoved(from: oldPosition, to: newPosition)
            board[newPosition.y][newPosition.x] = board[oldPosition.y][oldPosition.x]
            board[oldPosition.y][oldPosition.x] = nil
            
        } else {
            
            throw BoardError.invalidMove
            
        }
        
    }
    
    
    private static func defaultBoard() -> [[Piece?]] {
        
        var defBoard = [[Piece?]](repeatElement([Piece?](repeatElement(nil, count: 8)), count: 8));
        
        // Fill the rows with pawns
        defBoard[1] = [Piece](repeating: Piece.init(pieceType: .pawn, pieceColor: .black), count: 8)
        defBoard[6] = [Piece](repeating: Piece.init(pieceType: .pawn, pieceColor: .white), count: 8)
        
        for i in 0...1 {
            
            let s = i * 3
            
            for j in 0...3 {
                
                let k = j - s
                if (k == -3 || k == 3) {
                    // Fill the first and last row of the board
                    defBoard[0][(4 * i + j)] = Piece.init(pieceType: PieceType(rawValue: k)!, pieceColor: .black)
                    defBoard[7][(4 * i + j)] = Piece.init(pieceType: PieceType(rawValue: -k)!, pieceColor: .white)
                } else {
                    defBoard[0][(4 * i + j)] = Piece.init(pieceType: PieceType(rawValue: abs(k))!, pieceColor: .black)
                    defBoard[7][(4 * i + j)] = Piece.init(pieceType: PieceType(rawValue: abs(k))!, pieceColor: .white)
                }
                
            }
            
        }
        
        return defBoard
    }
    
    // Checks if move is allowed from every factor
    private func moveAllowed(from oldPos: (x: Int, y: Int), to newPos: (x: Int, y: Int)) -> Bool {
        
        let optPiece = board[oldPos.y][oldPos.x]
        
        
        if ((max(newPos.y, newPos.x) > 8) || (min(newPos.y, newPos.x) < 0)) {
            return false
        }
        
        let absDiff = (y: abs(newPos.y - oldPos.y), x: abs(newPos.x - oldPos.x))
        
        if let piece = optPiece {
            
            // If the current selected piece is not on turn, the move is automatically invalid
            if piece.color == turnOfColor {
                
                // Logic checking if there are any pieces between oldPos and newPos, EXCLUDES THE ENDPOINT
                let pathClear = !piecesBetween(position1: oldPos, position2: newPos)
                
                var capturesPiece = false
                
                // Check if the endpoint contains a piece of the same color, if so, dont allow the move
                if (board[newPos.y][newPos.x]?.color == piece.color) {
                    
                    return false
                    
                }
                    // If the endpoint is not empty and its not of the same color as current piece, we know that the endpoint is gonna be captured
                else if (board[newPos.y][newPos.x] != nil) {
                    
                    capturesPiece = true
                    
                }
                
                switch piece.type {
                    
                case .pawn:
                    let diff = (x: newPos.x - oldPos.x, y: newPos.y - oldPos.y)
                    if ((max(diff.x, diff.y) > 0 && piece.color == .black) || (min(diff.x, diff.y) < 0 && piece.color == .white)) {
                        if ((absDiff.x == 0) && (absDiff.y == 1) && !capturesPiece) {
                            return true
                        } else if (absDiff.y == 2 && pathClear) { // Starting position double move
                            // Check if position is a starting pos for a pawn
                            if (oldPos.y == 1 || oldPos.y == 6) {
                                return true
                            }
                        } else if (absDiff.y == 1 && (absDiff.x == absDiff.y) && capturesPiece) { // If the pawn captures a piece at the end, allow it to move diagonally
                            return true
                        }
                    }
                case .bishop:
                    if (absDiff.x == absDiff.y && pathClear) {
                        return true
                    }
                case .king:
                    if (max(absDiff.x, absDiff.y) == 1) {
                        return true
                    }
                case .knight:
                    if ((absDiff.x == 2 && absDiff.y == 1) || (absDiff.x == 1 && absDiff.y == 2)) {
                        return true
                    }
                case .queen:
                    if (((absDiff.x == absDiff.y) || min(absDiff.x, absDiff.y) == 0) && pathClear) {
                        return true
                    }
                case .rook:
                    if (min(absDiff.x, absDiff.y) == 0 && pathClear) {
                        return true
                    }
                }
                
                
                
            }
        }
        
        return false
    }
    
    private func piecesBetween(position1: (x: Int, y: Int), position2: (x: Int, y: Int)) -> Bool {
        
        
        let absDiff = (y: abs(position1.y - position2.y), x: abs(position1.x - position2.x))
        
        let maxX = max(position1.x, position2.x)
        let minX = min(position1.x, position2.x)
        
        let maxY = max(position1.y, position2.y)
        let minY = min(position1.y, position2.y)
        
        // The case where the movement is purely horizontal
        if (absDiff.y == 0) {
            
            for i in (minX + 1)..<maxX {
                
                if (board[i][position2.x] != nil) {
                    return true
                }
                
            }
            
        } else if (absDiff.x == 0) { // The case where the movement is purely vertical
            
            for i in (minY + 1)..<maxY {
                
                if (board[position2.y][i] != nil) {
                    
                    return true
                    
                }
                
            }
            
        } else if (absDiff.x == absDiff.y) { // The case where the movement is diagonal
            
            for i in (minY + 1)..<maxY {
                
                if (board[i][i] != nil) {
                    
                    return true
                    
                }
                
            }
            
            
        }
        
        
        return false
    }
    
}
