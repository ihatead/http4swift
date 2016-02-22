/*
 The MIT License (MIT)

 Copyright (c) 2015 Shun Takebayashi

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

import Nest

#if os(OSX)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

enum WriterError: ErrorType {
    case GenericError(error: Int32)
}

public class HTTPResponseWriter {

    let socket: Int32

    init(socket: Int32) {
        self.socket = socket
    }

    public func write(bytes: UnsafePointer<Int8>) throws {
#if os(Linux)
        let flags = Int32(MSG_NOSIGNAL)
#else
        let flags = Int32(0)
#endif

        var rest = Int(strlen(bytes))
        while rest > 0 {
            let sent = send(socket, bytes, rest, flags)
            if sent < 0 {
                throw WriterError.GenericError(error: errno)
            }
            rest -= sent
        }
    }

    public func write(response: ResponseType) throws {
        try write("HTTP/1.0 \(response.statusLine)\r\n")
        var lengthWrote = false
        for header in response.headers {
            try write("\(header.0): \(header.1)\r\n")
            if header.0 == "Content-Length" {
                lengthWrote = true
            }
        }
        if !lengthWrote {
            if let bytes = response.body?.bytes() {
                try write("Content-Length: \(bytes.count - 1)\r\n")
            }
        }
        try write("\r\n")
        if let body = response.body?.bytes() {
            try write(body)
        }
    }

}
