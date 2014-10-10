;;; helm-deft.el --- helm module for grepping note files over directories

;; Copyright (C) 2014 Derek Feichtinger
 
;; Author: Derek Feichtinger <derek.feichtinger@psi.ch>
;; Keywords: convenience
;; Homepage: https://github.com/dfeich/helm-deft
;; Version: TODO

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'helm)
(require 'helm-grep)
(require 'f)

(defgroup helm-deft nil
  "customization group for the helm-deft utility" :group 'helm :version 24.3)

(defcustom helm-deft-dir-list
  '("~/Documents" "~/Dropbox/org/deft")
  "list of directories for helm-deft to search recursively"
  :group 'helm-deft
  )

(defcustom helm-deft-extension "org"
  "defines file extension to be searched for")

(defvar helm-deft-file-list ""
  "list of candidate files")

(defvar helm-source-deft-fn
  '((name . "File Names")
    (init . (lambda ()
	      (progn (setq helm-deft-file-list (helm-deft-fname-search))
		     (with-current-buffer (helm-candidate-buffer 'local)
			  (insert (mapconcat 'identity
					     helm-deft-file-list "\n"))))))
    (candidates-in-buffer)
    ;;(candidates . helm-deft-fname-search)   ;; would be too slow
    ;; (action . (("open file" . (lambda (candidate)
    ;; 				(find-file candidate)))))
    (type . file)
    ;;(persistent-help . "show name")    
    )
  "Source definition for matching filenames of the `helm-deft' utility")

(defvar helm-source-deft-filegrep
  '((name . "File Contents")
    (candidates-process . helm-deft-fgrep-search)
    ;;(action . (("return name " . (lambda (candidate) candidate))))
    (action . helm-grep-action)))

(defun helm-deft-fname-search ()
  "search all preconfigured directories for matching files and return the
filenames as a list"
  (cl-loop for dir in helm-deft-dir-list
	   collect (f--files dir (equal (f-ext it) helm-deft-extension) t)
	   into reslst
	   finally (return (apply #'append reslst)))  
  )

(defun helm-deft-fgrep-search ()
  (let* ((srch-str (car (split-string helm-pattern " ")))
	 (shcmd (format "grep -an -e \"%s\" %s"
				       srch-str
				       (mapconcat 'identity
						  helm-deft-file-list " "))))
    (helm-log "grep command: %s" shcmd)
    (start-process-shell-command "helm-deft-proc" "*helm-deft-proc*"
				 shcmd))
  )

;;;###autoload
(defun helm-deft ()
  "Preconfigured `helm' module for locating note files where either the
filename or the file contents match the query string"
  (interactive)
  (helm :sources '(helm-source-deft-fn helm-source-deft-filegrep)))

(provide 'helm-deft)

;; I could also try to use
;; find . -not -path "*/.git/*" -name "*.org" -type f
;; grep -an -e "o[^ ]*let" *.el
