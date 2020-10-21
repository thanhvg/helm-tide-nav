;;; helm-tide-nav.el --- Helm interface to tide-nav -*- lexical-binding: t -*-

(require 'helm)
(require 'tide)

;;;###autoload
(defun helm-tide-nav ()
  "Find ts/js project symbols."
  (interactive)
  (helm :sources 'helm-source-tide-nav
        :buffer "*helm tide nav*"))

(defun helm-tide-nav-fetch ()
  (with-helm-current-buffer ;; very important otherwise tide will run on a nil buffer and it will call global tsserver
    (let ((response (tide-command:navto helm-pattern)))
      (tide-on-response-success response
          (when-let ((navto-items (plist-get response :body))
                     (cutoff (length (tide-project-root))))
            (setq navto-items (funcall tide-navto-item-filter navto-items))
            (seq-map (lambda (navto-item)
                       (cons
                        (format "%s: %s"
                                ;; (car (reverse (split-string (plist-get navto-item :file) "\\/")))
                                (substring (plist-get navto-item :file) cutoff)
                                (plist-get navto-item :name))
                        navto-item))
                     navto-items))))))

(defvar helm-source-tide-nav
  (helm-build-sync-source "Project Symbols"
    :candidates #'helm-tide-nav-fetch
    :action #'tide-jump-to-filespan
    ;; :action (lambda (cdd) (message "%s" cdd))
    :volatile t
    :requires-pattern 3))

(provide 'helm-tide-nav)
