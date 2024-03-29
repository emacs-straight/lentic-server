;;; lentic-server.el --- Web Server for Emacs Literate Source  -*- lexical-binding:t -*-

;;; Header:

;; This file is not part of Emacs

;; Author: Phillip Lord <phillip.lord@newcastle.ac.uk>
;; Maintainer: Phillip Lord <phillip.lord@newcastle.ac.uk>
;; Version: 0.2
;; Package-Requires: ((lentic "0.8")(web-server "0.1.1"))

;; The contents of this file are subject to the GPL License, Version 3.0.

;; Copyright (C) 2015-2024  Free Software Foundation, Inc.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Serves up lentic files as web documents.

;;; News:

;; Since 2016:

;; - Activate `lexical-binding', and remove dependency on `f'.
;; - Distribute on GNU ELPA.

;;; Code:

;; #+begin_src emacs-lisp
(require 'lentic-doc)
(require 'web-server)

(defvar lentic-server-doc t)

(defvar lentic-server--server nil)

(defun lentic-server--split (filename)
  (cl-assert filename)
  (let ((parts ()))
    (while
        (let* ((file (directory-file-name filename))
               (dir (file-name-directory file)))
          (if (and dir (< (length dir) (length file)))
              (progn
                (push (file-name-nondirectory file) parts)
                (setq filename dir))
            (push file parts)
            nil)))
    parts))

;;;###autoload
(defun lentic-server-start ()
  (interactive)
  (setq lentic-server--server
        (ws-start
         (lambda (request)
           (with-slots (process headers) request
             (-let* (((_ package . _)
                      (lentic-server--split (cdr (assoc :GET headers))))
                     )
               (cond
                ((not package)
                 (lentic-ws-send-list process (lentic-doc-all-lentic-features)))
                ((-contains? (lentic-doc-all-lentic-features)
                             package)
                 (progn
                   (lentic-doc-ensure-doc package)
                   (ws-send-file process
                                 (lentic-doc-package-doc-file package))))
                ((-contains? lentic-doc-allowed-files package)
                 (ws-send-file process (locate-file package load-path)))
                (t
                 (ws-send-404 process))))))
         9010)))

;; this needs to go to web-server!
(defun lentic-ws-send-list (proc list)
  "Send a listing of links to PROC.
The elements in list should be a cons of anchor/link, or a string
which will be used as both URL and anchor."
  (ws-response-header proc 200 (cons "Content-type" "text/html"))
  (process-send-string proc
    (concat "<ul>"
            (mapconcat
             (lambda (f)
               (if (listp f)
                   (format "<li><a href=\"%s\">%s</li>"
                           (cdr f) (car f))
                 (format "<li><a href=\"%s\">%s</li> "
                         f f)))
             list
             "\n")
            "</ul>")))


;;;###autoload
(defun lentic-server-stop ()
  (interactive)
  (ws-stop lentic-server--server))

;;;###autoload
(defun lentic-server-browse ()
  (interactive)
  (unless lentic-server--server
    (lentic-server-start))
  (browse-url-default-browser
   "http://localhost:9010/"))

(provide 'lentic-server)
;;; lentic-server.el ends here
;; #+end_src
