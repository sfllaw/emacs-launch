;;; launch.el --- launch files with OS-standard associated applications.

;; Copyright (C) 2013  Simon Law <sfllaw@sfllaw.ca>

;; Author: Simon Law <sfllaw@sfllaw.ca>
;; URL: https://github.com/sfllaw/emacs-launch
;; Version: 1.0.1
;; Created: 12 Jun 2012
;; Keywords: convenience processes

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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

;; Launch files and directories using the associated applications provided by
;; your operating system.

;; If you're like me, you love using Emacs for all of your text
;; management needs.  But sometimes, there are documents that you'd like
;; to open with other programs.

;; For instance, you might want to launch your file manager to look at
;; pretty thumbnails in the current directory.  Or you're editing HTML and
;; want to launch your document in the system's web browser.

;; Launch makes it easy to do this by using your OS's built-in
;; file-associations to launch the appropriate program for a particular
;; file.


;;; Installation:

;; Launch is available from MELPA <http://melpa.milkbox.net/>.
;; Just run \\[package-install] and install `launch'.

;; Then, in your ~/.emacs configuration, add:
;;     (global-launch-mode +1)

;; If you only want to enable it for certain modes, add:
;;     (add-hook 'html-mode 'turn-on-launch-mode)

;;; Usage:

;; With a buffer open to a file, launch it with C-c ! !. Or, to open
;; the file manager for the current directory, use C-c ! d. Try it with
;; `ido-everywhere' turned on.

;; Inside special buffers like `dired' or `vc-dir', launch marked files using
;; C-c ! !. To just launch the default directory itself, use C-c ! d.

;;; Bugs:

;; Please report bugs to http://github.com/sfllaw/emacs-launch/issues

;; * This library is untested on Windows or Mac OS X. Pull requests welcome.

;;; Code:


;;;; Customize

;;;###autoload
(defgroup launch nil
  "Launch using OS-standard associated applications."
  :group 'processes)

;;;###autoload
(defcustom launch-program
  (cond ((eq system-type 'darwin) (executable-find "open"))
        ((or (eq system-type 'windows-nt)
             (eq system-type 'cygwin)) (executable-find "start.exe"))
        (t (or (executable-find "xdg-open")
               (executable-find "exo-open")
               (executable-find "kde-open")
               (executable-find "gnome-open"))))
  "Program to use as a launcher."
  :group 'launch
  :type 'string)

;;;###autoload
(defcustom launch-minimum-confirm 5
  "Minimum number of files before confirmation.

If the number of files to launch exceeds this minimum, confirm
with the user."
  :group 'launch
  :type 'integer)


;;;; Basic

;;;###autoload
(defun launch-file (filename)
  "Launch FILENAME using its associated program."
  (interactive
   (let ((file buffer-file-name)
         (file-name nil)
         (file-dir nil))
     (unless (and (boundp 'ido-everywhere) ido-everywhere)
       (and file
          (setq file-name (file-name-nondirectory file)
                file-dir (file-name-directory file))))
     (list (read-file-name
            "Launch file: " file-dir file t file-name))))
  (when (null launch-program)
      (error "%s" "`launch-program' not defined."))
  (let ((process-connection-type nil))
    (start-process "launcher" nil
                   launch-program (expand-file-name filename))))

;;;###autoload
(defun launch-directory (dirname-or-filename)
  "Launch the file manager for DIRNAME-OR-FILENAME.

If DIRNAME-OR-FILENAME is a file, launch its directory."
  (interactive
   (list (read-directory-name
          "Launch directory: " nil default-directory t nil)))
  (let ((dirname (if (file-directory-p dirname-or-filename)
                     (file-name-as-directory dirname-or-filename)
                   (file-name-directory dirname-or-filename))))
    (launch-file dirname)))


;;;###autoload
(defun launch-files (file-list &optional confirm)
  "Launch each file in FILE-LIST using its associated program.

If CONFIRM is set, ask the user if they meant to open a large
number of files."
  (when (cond ((and confirm
                    (> (length file-list) launch-minimum-confirm))
               (y-or-n-p (format "Confirm--launch %d files? "
                                 (length file-list))))
              (t))
      (mapc 'launch-file file-list)))


;;;; Mode

;;;###autoload
(define-minor-mode launch-mode
  "Toggle Launch mode on or off.
With a prefix argument ARG, enable Launch mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil.

Turning on launch-mode will add keybindings for `launch-file' and
`launch-directory'."
  :keymap '(("\C-c!!" . launch-file)
            ("\C-c!d" . launch-directory)))

;;;###autoload
(defun turn-on-launch-mode ()
  "Unconditionally turn on Launch mode."
  (launch-mode +1))

;;;###autoload
(defun turn-off-launch-mode ()
  "Unconditionally turn off Launch mode."
  (launch-mode -1))

;;;###autoload
(define-globalized-minor-mode global-launch-mode launch-mode
  turn-on-launch-mode)


;;;; dired

(eval-when-compile
  (require 'dired))

(defun launch-files-dired (&optional arg file-list)
  "Launch the marked files.
If no files are marked or a numeric prefix arg is given, the next
ARG files are used.  Just \\[universal-argument] means the current
file.

In a noninteractive call (from Lisp code), you must specify
the list of file names explicitly with the FILE-LIST argument, which
can be produced by `dired-get-marked-files', for example."
  (interactive
   (when (fboundp 'dired-get-marked-files)
     (list
      current-prefix-arg
      (dired-get-marked-files t current-prefix-arg))))
  (launch-files file-list (called-interactively-p 'any)))

(defun launch-directory-dired ()
  "Launch the visited directory."
  (interactive)
  (when (fboundp 'dired-current-directory)
    (launch-directory (dired-current-directory))))

;; Provide a special keymap for dired-mode
(defvar launch-mode-dired-map
  (easy-mmode-define-keymap
   '(("\C-c!!" . launch-files-dired)
     ("\C-c!d" . launch-directory-dired))
   nil
   nil
   '(:inherit launch-mode-map))
  "Keymap for `launch-mode' in `dired-mode'.")

;; Install the keymap as an override in dired-mode buffers.
(eval-after-load 'dired
  '(progn
     (defun launch-dired-remap ()
       "Override `launch-mode-map' in `dired-mode'."
       (push `(launch-mode . ,launch-mode-dired-map)
             minor-mode-overriding-map-alist))

     (add-hook 'dired-mode-hook 'launch-dired-remap)))


;;; vc-dir

(eval-when-compile
  (require 'vc-dir))

(defun launch-files-vc-dir (&optional file-list)
  "Launch the marked files.
If no files are marked, the current file is used.

In a noninteractive call (from Lisp code), you must specify
the list of file names explicitly with the FILE-LIST argument, which
can be produced by `vc-dir-marked-files', for example."
  (interactive
   (when (and (fboundp 'vc-dir-current-file)
              (fboundp 'vc-dir-marked-files))
     (list
      (or (vc-dir-marked-files)
          (list (vc-dir-current-file))))))
  (launch-files file-list (called-interactively-p 'any)))

(defun launch-directory-vc-dir ()
  "Launch the visited directory."
  (interactive)
  (launch-directory default-directory))

;; Provide a special keymap for vc-dir-mode
(defvar launch-mode-vc-dir-map
  (easy-mmode-define-keymap
   '(("\C-c!!" . launch-files-vc-dir)
     ("\C-c!d" . launch-directory-vc-dir))
   nil
   nil
   '(:inherit launch-mode-map))
  "Keymap for `launch-mode' in `vc-dir-mode'.")

;; Install the keymap as an override in vc-dir-mode buffers.
(eval-after-load 'vc-dir
  '(progn
     (defun launch-vc-dir-remap ()
       "Override `launch-mode-map' in `vc-dir-mode'."
       (push `(launch-mode . ,launch-mode-vc-dir-map)
             minor-mode-overriding-map-alist))

     (add-hook 'vc-dir-mode-hook 'launch-vc-dir-remap)))


(provide 'launch)
;;; launch.el ends here
