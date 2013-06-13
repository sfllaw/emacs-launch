Launch
======

An Emacs library for launching files and directories using the
associated applications provided by your operating system.

If you're like me, you love using Emacs for all of your text
management needs. But sometimes, there are documents that you'd like
to open with other programs.

For instance, you might want to launch your file manager to look at
pretty thumbnails in the current directory. Or you're editing HTML and
want to launch your document in the system's web browser.

**Launch** makes it easy to do this by using your OS's built-in
file-associations to launch the appropriate program for a particular
file.


Installation
------------

**Launch** is available from [MELPA](http://melpa.milkbox.net/).
Just run `M-x package-install` and install `launch`.

Then, in your `~/.emacs` configuration, add:

    (global-launch-mode +1)

If you only want to enable it for certain modes, add:

    (add-to-hook 'html-mode 'turn-on-launch-mode)

Usage
-----

With a buffer open to a file, launch it with `C-c ! !`. Or, to open
the file manager for the current directory, use `C-c ! d`. Try it with
*ido-everywhere* turned on.

Inside special buffers like *dired* or *vc-dir*, launch marked files using
`C-c ! !`. To just launch the default directory itself, use `C-c ! d`.


Bugs
----

Please report bugs to http://github.com/sfllaw/emacs-launch/issues.

* This library has only been tested on Emacs 24.3. Pull requests welcome.
* This library is untested on Windows or Mac OS X. Pull requests welcome.
