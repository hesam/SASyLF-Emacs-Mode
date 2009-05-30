;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; THIS IS A HACK ADAPTED FROM: emacs gause-mode:                            ;;
;;   http://www.econ.yale.edu/~steveb/gauss-mode.el                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; sasylf-mode.el - major mode for editing SASyLF proofs with GNU Emacs
;;
;; This major mode for GNU Emacs provides support for editing SASyLF
;; proofs. Syntax Highlighting, Automatic Indentation and Completions 
;; for block structures are supported.
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                           ;;
;; - to enter sasylf-mode automatically when editing .slf files, put         ;;
;;   something like this in your .emacs file:                                ;; 
;;                                                                           ;;
;;      (autoload 'sasylf-mode "<path>/sasylf-mode.el"                       ;;
;;                             "Major mode for SASyLF proof files" t)        ;;
;;      (add-hook 'sasylf-mode-hook 'turn-on-font-lock)                      ;; 
;;      (setq auto-mode-alist                                                ;;
;;            (append (list '("\\.slf" . sasylf-mode)) auto-mode-alist))     ;;
;;                                                                           ;;
;;    - and for faster loads:                                                ;;
;;                                                                           ;;
;;       C-x f sasylf-mode.el                                                ;;
;;       M-x byte-compile-file sasylf-mode.el                                ;;
;;                                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; Constants used in all Sasylf-mode buffers.
(defconst sasylf-indent-level 2
  "*The indentation in Sasylf-mode.")

(defconst sasylf-comment-column 40
  "*The goal comment column in Sasylf-mode buffers.")

;; Syntax Table
(defvar sasylf-mode-syntax-table nil
  "Syntax table used in Sasylf-mode buffers.")

(if sasylf-mode-syntax-table
    ()
  (setq sasylf-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?* ". 23b" sasylf-mode-syntax-table)
  (modify-syntax-entry ?/ ". 124" sasylf-mode-syntax-table)
  (modify-syntax-entry ?\n ">" sasylf-mode-syntax-table)
  (modify-syntax-entry ?\^m ">" sasylf-mode-syntax-table)
  (set-syntax-table sasylf-mode-syntax-table))

;; Abbrev Table
(defvar sasylf-mode-abbrev-table nil
  "Abbrev table used in Sasylf-mode buffers.")

(define-abbrev-table 'sasylf-mode-abbrev-table ())

;; Mode Map
(defvar sasylf-mode-map ()
  "Keymap used in sasylf-mode.")

(if sasylf-mode-map
    ()
  (setq sasylf-mode-map (make-sparse-keymap))
  (define-key sasylf-mode-map "\r" 'sasylf-return)
  (define-key sasylf-mode-map "\t" 'sasylf-indent-line)
  (define-key sasylf-mode-map "\C-ct" 'sasylf-line-type)
  (define-key sasylf-mode-map "\C-ci" 'sasylf-indent-type)
  (define-key sasylf-mode-map "\M-\r" 'sasylf-return-no-autocomp))

(defvar sasylf-font-lock-keywords
  '(("\\<terminals\\>\\|\\<syntax\\>\\|\\<judgment\\>\\|\\<assumes\\>\\|\\<lemma\\>\\|\\<theorem\\>\\|\\<induction\\>\\|\\<case\\>\\|\\<analysis\\>\\|\\<hypothesis\\>\\|\\<rule\\>\\|\\<end\\>\\|\\<is\\>" . font-lock-keyword-face)
    ("\\<forall\\>\\|\\<exists\\>\\|\\<by\\>\\|\\<on\\>" . font-lock-function-name-face)
    ("\\(\-\-\-\-.*$\\)" . font-lock-type-face)
    ("\\<unproved\\>" . font-lock-comment-face)
    ("\\(\\S-+:\\)" . font-lock-type-face))
    "Keyword highlighting specification for sasylf-mode.")

;; Sasylf Mode
(defun sasylf-mode ()
  "Major mode for editing Sasylf source files.  Version 1.0, 18 Oct, 2008.
Will run sasylf-mode-hook if it is non-nil. 

Special Key Bindings:
\\{sasylf-mode-map}
Variables:
  sasylf-indent-level                   Level to indent blocks.
  sasylf-comment-column                 Goal column for on-line comments.
  fill-column                           Column used in auto-fill (default=70).
Commands:
  sasylf-mode                           Enter Sasylf major mode.
  sasylf-return                         Handle return with indenting and autocompletion (key: Return)
  sasylf-return-no-autocomp             Handle return with indenting no autocompletion (key: Meta+Return)
  sasylf-indent-line                    Indent line for structure.
  sasylf-comment-indent                 Compute indent for comment.

To add automatic support put something like the following in your .emacs file:
   \(autoload 'sasylf-mode \"sasylf-mode.el path\" \"Major mode for SASyLF proof files\" t\)
   \(add-hook 'sasylf-mode-hook 'turn-on-font-lock)
   \(setq auto-mode-alist (append (list '\(\"\\\\.slf\" . sasylf-mode\)\) auto-mode-alist\)\)"
  (interactive)
  (kill-all-local-variables)
  (use-local-map sasylf-mode-map)
  (setq major-mode 'sasylf-mode)
  (setq mode-name "Sasylf")
  (setq local-abbrev-table sasylf-mode-abbrev-table)
  (set-syntax-table sasylf-mode-syntax-table)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'paragraph-ignore-fill-prefix)
  (setq paragraph-ignore-fill-prefix t)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'sasylf-indent-line)
  (make-local-variable 'comment-column)
  (setq comment-column 'sasylf-comment-column)
  (make-local-variable 'fill-column)
  (setq fill-column default-fill-column)
  (set (make-local-variable 'comment-start) "/\\*")
  (set (make-local-variable 'comment-end) "\\*/")
  (set (make-local-variable 'comment-start-skip) "/\\*+ *\\|// *")
  (set (make-local-variable 'comment-multi-line) t)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'font-lock-defaults)
       '(sasylf-font-lock-keywords))

  (run-hooks 'sasylf-mode-hook))

(defun sasylf-return ()
  "Handle carriage return in Sasylf-mode with autocompletion."
  (interactive)
  (if (sasylf-block-end-line)
      (sasylf-indent-line))
  (sasylf-auto-complete))

(defun sasylf-return-no-autocomp ()
  "Handle carriage return in Sasylf-mode without autocompletion."
  (interactive)
  (if (sasylf-block-end-line)
      (sasylf-indent-line))
  (newline)
  (sasylf-indent-line))

(defun sasylf-auto-complete ()
  (let ((checked (and (looking-at "\s*$") (sasylf-block-start-line))))
    (cond (checked
	   (save-excursion
	     (newline)
	     (insert checked)
	     (sasylf-indent-line))))
    (newline)
    (sasylf-indent-line)))

(defun sasylf-indent-line ()
  "Indent a line in Sasylf-mode."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (delete-horizontal-space)
    (indent-to (sasylf-calc-indent)))
  (skip-chars-forward " \t"))

(defvar sasylf-last-indent-type "unknown"
  "String to tell line type.")

(defun sasylf-calc-indent ()
  "Return the appropriate indentation for this line as an int."
  (let ((indent 0))
    (save-excursion
      (forward-line -1)                 ; compute indent based on previous
      (if (sasylf-empty-line)               ;   non-empty line
          (re-search-backward "[^ \t\n]" 0 t))
      (cond
       ((sasylf-empty-line) 
        (setq sasylf-last-indent-type "empty"))
       ((sasylf-block-beg-end-line)
        (setq sasylf-last-indent-type "block begin-end"))
       ((sasylf-block-start-line)
        (setq sasylf-last-indent-type "block begin")
        (setq indent sasylf-indent-level))
       (t
        (setq sasylf-last-indent-type "other")))
      (setq indent (+ indent (current-indentation))))
    (if (sasylf-block-end-line) (setq indent (- indent sasylf-indent-level)))
    (if (< indent 0) (setq indent 0))
    indent))

(defun sasylf-empty-line ()
  "Returns t if current line is empty."
  (save-excursion
    (beginning-of-line)
    (looking-at "^[ \t]*$")))

(defun sasylf-block-start-line ()
  "Returns the name of block (lemma,case,...) as a string 
   if current line is begining of case block, false otherwise"
  (cond 
   ((save-excursion (beginning-of-line) (or (looking-at "^is\s*$") (looking-at "^.*[ \t]+is\s*$")))
    "end case")
   ((save-excursion
      (beginning-of-line) (looking-at "^\s*lemma"))
    "end lemma")
   ((save-excursion
      (beginning-of-line) (looking-at "^\s*theorem"))
    "end theorem")
   ((save-excursion
      (beginning-of-line) (looking-at "^.*by\s+induction\s+on"))
    "end induction")
   ((save-excursion
      (beginning-of-line) (looking-at "^.*by\s+case\s+analysis\s+on"))
    "end case analysis")
   (t nil)))

(defun sasylf-eoln-point ()
  "Returns point for end-of-line in Sasylf-mode."
  (save-excursion
    (end-of-line)
    (point)))

(defconst sasylf-block-beg-kw "\\(is\\|\\s*lemma \\|\\s*theorem \\|induction on\\|analysis on\\)"
  "Regular expression for keywords which begin blocks in Sasylf-mode.")

(defconst sasylf-block-end-kw "\\(end\\)"
  "Regular expression for keywords which end blocks.")

(defun sasylf-block-end-line ()
  "Returns t if line contains end of Sasylf block."
  (save-excursion
    (beginning-of-line)
    (looking-at (concat "\\([^%@\n]*[ \t]\\)?" sasylf-block-end-kw))))


(defun sasylf-block-beg-end-line ()
  "Returns t if line contains matching block begin-end in Sasylf-mode."
  (save-excursion
    (beginning-of-line)
    (looking-at (concat
                 "\\([^%@\n]*[ \t]\\)?" sasylf-block-beg-kw 
                 "." "\\([^%@\n]*[ \t]\\)?" sasylf-block-end-kw))))

(provide 'sasylf-mode)

;; --- last line of sasylf-mode.el --- 

