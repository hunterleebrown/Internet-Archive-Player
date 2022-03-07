//
//  IAMediaUtils.swift
//  IA Music
//
//  Created by Brown, Hunter on 10/29/15.
//  Copyright © 2015 Hunter Lee Brown. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
//import iaAPI

struct IAFontMapping
{
    static let IAFontFamily = "Iconochive-Regular"
    static let IAFont = UIFont(name: IAFontMapping.IAFontFamily, size: 30)
    
    static let HAMBURGER = "\u{21f6}"
    static let MEDIAPLAYER = "\u{0001F3AC}"
    static let SEARCH = "\u{0001F50D}"
    static let FAVORITE = "\u{2661}"
    static let BACK = "\u{02c2}"
    static let INFO = "\u{0069}"
    static let SHARE = "\u{0001F381}"
    static let GLOBE = "\u{0001F5FA}"
    static let VIEWS = "\u{0001F441}"
    static let FOLDER = "\u{0001F5C3}"
    static let PLUS = "\u{2295}"
    static let CLOCK = "\u{0001F551}"
    static let STAR = "\u{2605}"
    static let GRID = "\u{229E}"
    static let QUESTION = "\u{2370}"
    
    static let SPEAKER_0 = "\u{0001F508}"
    static let SPEAKER_1 = "\u{0001F509}"
    static let SPEAKER_2 = "\u{0001F50A}"
    
    static let TEXTASC = "\u{0001F524}"
    static let TEXTDSC = "\u{0001F525}"
    
    static let UP = "\u{25B4}"
    static let DOWN = "\u{25BE}"
    
    static let ARCHIVE = "\u{0001F3DB}"
    static let CLOSE = "\u{0001F5D9}"
    
    static let PLAY = "\u{25B6}"
    static let FFORWARD = "\u{23E9}"
    static let RREVERSE = "\u{23EA}"
    static let PAUSE = "\u{23F8}"
    static let FULLSCREEN = "\u{26F6}"
    static let RANDOM = "\u{0001f500}"
    
    static let ANTENA = "\u{0001F4F6}"
    
    static let AUDIO = "\u{0001F568}"
    
    static let DOTS = "\u{25A6}"
    
    static let VIDEO = "\u{0001F39E}"
    static let COLLECTION = "\u{2317}"
    static let IMAGE = "\u{0001F5BC}"
    static let BOOK = "\u{0001F56E}"
    static let SOFTWARE = "\u{0001F4BE}"
    static let ETREE = "\u{0001F3A4}"
    
    static let TRASH = "\u{0001F5D1}"
    static let PENCIL = "\u{270E}"
    static let CHECK = "\u{2713}"
    
    
    
}

struct IAColors
{
    static let AUDIO_COLOR = UIColor(red:19.0/255.0, green:155.0/255.0, blue:235.0/255.0, alpha:1.0)
    static let VIDEO_COLOR = UIColor(red:235.0/255.0, green:77.0/255.0, blue:59.0/255.0, alpha:1.0)
    static let BOOK_COLOR = UIColor(red:246.0/255.0, green:155.0/255.0, blue:47.0/255.0, alpha:1.0)
    static let IMAGE_COLOR = UIColor(red:153.0/255.0, green:132.0/255.0, blue:189.0/255.0, alpha:1.0)
    static let COLLECTION_COLOR = UIColor(red:53.0/255.0, green:118.0/255.0, blue:190.0/255.0, alpha:1.0)
    static let SOFTWARE_COLOR = UIColor(red:142.0/255.0, green:197.0/255.0, blue:63.0/255.0, alpha:1.0)
    static let ETREE_COLOR = UIColor(red:19.0/255.0, green:155.0/255.0, blue:235.0/255.0, alpha:1.0)
    static let VIEWS_COLOR = UIColor(red:117.0/255.0, green:117.0/255.0, blue:117.0/255.0, alpha:1.0)
    
    static let COLLECTION_BACKGROUND_COLOR = UIColor(red:133.0/255.0, green:133.0/255.0, blue:133.0/255.0, alpha:1.0)
    static let BUTTON_DEFAULT_SELECT_COLOR = UIColor(red:67.0/255.0, green:139.0/255.0, blue:202.0/255.0, alpha:1.0)
    
    static let fairyRed = UIColor(red: 201.0/255.0, green: 26.0/255.0, blue: 33.0/255.0, alpha: 1.0)
    static let fairyRedAlpha = UIColor(red: 201.0/255.0, green: 26.0/255.0, blue: 33.0/255.0, alpha: 0.66)
    static let fairyCream = UIColor(red: 255.0/255.0, green: 239.0/255.0, blue: 189.0/255.0, alpha: 1.0)
    static let blackSheer = UIColor(red: 0, green: 0, blue: 0, alpha: 0.66)
    static let droppy = UIColor(red: 66/255.0, green: 66/255.0, blue: 66/255.0, alpha: 1.0)

}

extension UIColor {

    class var fairyRed: UIColor {
        return IAColors.fairyRed
    }

    class var fairyRedAlpha: UIColor {
        return IAColors.fairyRedAlpha
    }

    class var fairyCream: UIColor {
        return IAColors.fairyCream
    }

    class var fairyCreamAlpha: UIColor {
        return UIColor(red: 255.0/255.0, green: 239.0/255.0, blue: 189.0/255.0, alpha: 0.75)
    }

    class var sheerBlack: UIColor {
        return IAColors.blackSheer
    }

}

extension Color {
    static let fairyRed = Color(UIColor.fairyRed)
    static let fairyRedAlpha = Color(UIColor.fairyRedAlpha)
    static let fairyCream = Color(UIColor.fairyCream)
    static let fairyCreamAlpha = Color(UIColor.fairyCreamAlpha)
    static let sheerBlack = Color(UIColor.sheerBlack)
    static let droopy = Color(IAColors.droppy)
}



enum IAFileFormat {
    case other
    case jpeg
    case gif
    case h264
    case mpeg4
    case mpeg4512kb
    case h264HD
    case djVuTXT
    case txt
    case processedJP2ZIP
    case vbrmp3
    case mp364Kbps
    case mp3128Kbps
    case mp3
    case mp396Kbps
    case png15
    case epub
    case image
    case png

//    var description : String {
//        return IAMediaUtils.stringFrom(IAMediaUtils.mediaTypeFrom(self))
//    }

}

enum IAMediaType {
    case none
    case audio
    case video
    case text
    case image
    case collection
    case any
    case software
    case etree

    var description : String {
        return IAMediaUtils.stringFrom(self)
    }

}

struct IAMediaUtils
{
    
//    static func downloadFilePath(_ response: HTTPURLResponse, file:IAPlayerFile) ->String{
//        let fileName = response.suggestedFilename!
//        return IAMediaUtils.removeSpecialCharsFromString(fileName)
//    }


    static func removeSpecialCharsFromString(_ text: String) -> String {
        let okayChars : Set<Character> =
        Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890.-_")
        return String(text.filter {
            okayChars.contains($0)
            })
    }
    
    static func imageUrlFrom(_ identifier: String)->URL?
    {
        let itemImageUrl = "https://archive.org/services/img/\(identifier)"
        if let url = URL(string: itemImageUrl) {
            return url
        } else {
            return nil
        }
    }
    
    static func mediaTypeFrom(_ fileFormat: IAFileFormat)->IAMediaType
    {
        switch fileFormat
        {
        case .mp3128Kbps:
            return IAMediaType.audio;
        case .mp364Kbps:
            return IAMediaType.audio;
        case .h264:
            return IAMediaType.video;
        case .h264HD:
            return IAMediaType.video;
        case .mp3:
            return IAMediaType.audio;
        case .mpeg4:
            return IAMediaType.video;
        case .vbrmp3:
            return IAMediaType.audio;
        case .mp396Kbps:
            return IAMediaType.audio;
        case .mpeg4512kb:
            return IAMediaType.video;
        case .epub:
            return IAMediaType.text;
        default: 
            return IAMediaType.none;
        }
    }
    
    
    static func iconStringFrom(_ mediaType: IAMediaType)->String
    {
        switch mediaType {
        case IAMediaType.audio:
            return IAFontMapping.AUDIO;
        case IAMediaType.collection:
            return IAFontMapping.COLLECTION;
        case IAMediaType.image:
            return IAFontMapping.IMAGE;
        case IAMediaType.text:
            return IAFontMapping.BOOK;
        case IAMediaType.video:
            return IAFontMapping.VIDEO;
        case IAMediaType.etree:
            return IAFontMapping.ETREE;
        case IAMediaType.any:
            return IAFontMapping.ARCHIVE;
        case IAMediaType.software:
            return IAFontMapping.SOFTWARE;
        default:
            return IAFontMapping.ARCHIVE;
        }
    }

    static func colorFrom(_ mediaType: IAMediaType)->UIColor
    {
        switch mediaType {
        case IAMediaType.audio:
            return IAColors.AUDIO_COLOR;
        case IAMediaType.collection:
            return IAColors.COLLECTION_COLOR;
        case IAMediaType.image:
            return IAColors.IMAGE_COLOR;
        case IAMediaType.text:
            return IAColors.BOOK_COLOR;
        case IAMediaType.video:
            return IAColors.VIDEO_COLOR;
        case IAMediaType.software:
            return IAColors.SOFTWARE_COLOR;
        case IAMediaType.etree:
            return IAColors.ETREE_COLOR;
        case IAMediaType.any:
            return UIColor.white
        default:
            return UIColor.white
        }
    }


    static func iconStringFrom(_ fileFormat: IAFileFormat)->String
    {
        switch fileFormat {
        case IAFileFormat.h264:
            return IAFontMapping.VIDEO;
        case IAFileFormat.mpeg4:
            return IAFontMapping.VIDEO;
        case IAFileFormat.mpeg4512kb:
            return IAFontMapping.VIDEO;
        case IAFileFormat.djVuTXT:
            return IAFontMapping.BOOK;
        case IAFileFormat.processedJP2ZIP:
            return IAFontMapping.BOOK;
        case IAFileFormat.txt:
            return IAFontMapping.BOOK;
        case IAFileFormat.jpeg:
            return IAFontMapping.IMAGE;
        case IAFileFormat.png:
            return IAFontMapping.IMAGE;
        case IAFileFormat.gif:
            return IAFontMapping.IMAGE;
        case IAFileFormat.image:
            return IAFontMapping.IMAGE;
        case IAFileFormat.epub:
            return IAFontMapping.BOOK;
        default:
            return IAFontMapping.AUDIO;
        }
    }
    
    static func colorFrom(_ fileFormat: IAFileFormat)->UIColor
    {
        switch fileFormat {
        case IAFileFormat.h264:
            return IAColors.VIDEO_COLOR;
        case IAFileFormat.mpeg4:
            return IAColors.VIDEO_COLOR;
        case IAFileFormat.mpeg4512kb:
            return IAColors.VIDEO_COLOR;
        case IAFileFormat.image:
            return IAColors.IMAGE_COLOR;
        case IAFileFormat.jpeg:
            return IAColors.IMAGE_COLOR;
        case IAFileFormat.png:
            return IAColors.IMAGE_COLOR;
        case IAFileFormat.gif:
            return IAColors.IMAGE_COLOR;
        case IAFileFormat.processedJP2ZIP:
            return IAColors.BOOK_COLOR;
        case IAFileFormat.h264HD:
            return IAColors.VIDEO_COLOR;
        case IAFileFormat.djVuTXT:
            return IAColors.BOOK_COLOR;
        case IAFileFormat.txt:
            return IAColors.BOOK_COLOR;
        case IAFileFormat.vbrmp3:
            return IAColors.AUDIO_COLOR;
        case IAFileFormat.mp3128Kbps:
            return IAColors.AUDIO_COLOR;
        case IAFileFormat.mp3:
            return IAColors.AUDIO_COLOR;
        case IAFileFormat.mp396Kbps:
            return IAColors.AUDIO_COLOR;
        case IAFileFormat.mp364Kbps:
            return IAColors.AUDIO_COLOR;
        case IAFileFormat.epub:
            return IAColors.BOOK_COLOR;
        default:
            return UIColor.black
        }
    }
    
    static func mediaTypeFrom(_ string: String)->IAMediaType
    {
        switch string
        {
        case "collection":
            return IAMediaType.collection
        case "audio":
            return IAMediaType.audio
        case "video":
            return IAMediaType.video
        case "texts" :
            return IAMediaType.text
        case "movies":
            return IAMediaType.video
        case "etree":
            return IAMediaType.etree
        case "software":
            return IAMediaType.software
        case "image":
            return IAMediaType.image
        default:
            return IAMediaType.any
        }
    }
    
    static func stringFrom(_ mediaType: IAMediaType)->String
    {
        switch mediaType
        {
        case IAMediaType.audio:
            return "audio";
        case IAMediaType.collection:
            return "collection";
        case IAMediaType.image:
            return "image";
        case IAMediaType.text:
            return "text";
        case IAMediaType.video:
            return "video";
        case IAMediaType.software:
            return "software";
        case IAMediaType.etree:
            return "concerts";
        case IAMediaType.any:
            return "";
        default:
            return "";
        }
    }
    
    
    static func fileFormatFrom(_ string: String)->IAFileFormat
    {
        switch string
        {
        case "VBR MP3":
            
            return IAFileFormat.vbrmp3
        case "h.264":
            return IAFileFormat.h264
        case "MPEG4":
            return IAFileFormat.mpeg4
        case "512Kb MPEG4":
            return IAFileFormat.mpeg4512kb
        case "128Kbps MP3":
            return IAFileFormat.mp3128Kbps
        case "MP3":
            return IAFileFormat.mp3
        case "96Kbps MP3":
            return IAFileFormat.mp396Kbps
        case "JPEG":
            return IAFileFormat.jpeg
        case "GIF":
            return IAFileFormat.gif
        case "64Kbps MP3":
            return IAFileFormat.mp364Kbps
        case "h.264 HD":
            return IAFileFormat.h264HD
        case "Single Page Processed JP2 ZIP":
            return IAFileFormat.processedJP2ZIP
        case "DjVuTXT":
            return IAFileFormat.djVuTXT
        case "Text":
            return IAFileFormat.txt
        case "PNG":
            return IAFileFormat.png
        case "EPUB":
            return IAFileFormat.epub
        case "Item Image":
            return IAFileFormat.image
        default:
            return IAFileFormat.other
        }
    }
    

}
