#     ____                                                 
#    / __ \____ _____  ____ ____  _____                    
#   / /_/ / __ `/ __ \/ __ `/ _ \/ ___/                    
#  / _, _/ /_/ / / / / /_/ /  __/ /                        
# /_/_|_|\__,_/_/ /_/\__, /\___/_/                   __    
#   / ____/___  ____/____/____ ___  ____ _____  ____/ /____
#  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
# / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  ) 
# \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/  
                                                         
from __future__ import (absolute_import, division, print_function)

from collections import deque
import os
import re

from ranger.api.commands import Command


class echo(Command):
    """:echo <text>

    Display the text in the statusbar.
    """

    def execute(self):
        self.fm.notify(self.rest(1))


class open_with(Command):

    def execute(self):
        app, flags, mode = self._get_app_flags_mode(self.rest(1))
        self.fm.execute_file(
            files=[f for f in self.fm.thistab.get_selection()],
            app=app,
            flags=flags,
            mode=mode)

    def tab(self, tabnum):
        return self._tab_through_executables()

    def _get_app_flags_mode(self, string):  # pylint: disable=too-many-branches,too-many-statements
        """Extracts the application, flags and mode from a string.

        examples:
        "mplayer f 1" => ("mplayer", "f", 1)
        "atool 4" => ("atool", "", 4)
        "p" => ("", "p", 0)
        "" => None
        """

        app = ''
        flags = ''
        mode = 0
        split = string.split()

        if len(split) == 1:
            part = split[0]
            if self._is_app(part):
                app = part
            elif self._is_flags(part):
                flags = part
            elif self._is_mode(part):
                mode = part

        elif len(split) == 2:
            part0 = split[0]
            part1 = split[1]

            if self._is_app(part0):
                app = part0
                if self._is_flags(part1):
                    flags = part1
                elif self._is_mode(part1):
                    mode = part1
            elif self._is_flags(part0):
                flags = part0
                if self._is_mode(part1):
                    mode = part1
            elif self._is_mode(part0):
                mode = part0
                if self._is_flags(part1):
                    flags = part1

        elif len(split) >= 3:
            part0 = split[0]
            part1 = split[1]
            part2 = split[2]

            if self._is_app(part0):
                app = part0
                if self._is_flags(part1):
                    flags = part1
                    if self._is_mode(part2):
                        mode = part2
                elif self._is_mode(part1):
                    mode = part1
                    if self._is_flags(part2):
                        flags = part2
            elif self._is_flags(part0):
                flags = part0
                if self._is_mode(part1):
                    mode = part1
            elif self._is_mode(part0):
                mode = part0
                if self._is_flags(part1):
                    flags = part1

        return app, flags, int(mode)

    def _is_app(self, arg):
        return not self._is_flags(arg) and not arg.isdigit()

    @staticmethod
    def _is_flags(arg):
        from ranger.core.runner import ALLOWED_FLAGS
        return all(x in ALLOWED_FLAGS for x in arg)

    @staticmethod
    def _is_mode(arg):
        return all(x in '0123456789' for x in arg)


class default_linemode(Command):

    def execute(self):
        from ranger.container.fsobject import FileSystemObject

        if len(self.args) < 2:
            self.fm.notify(
                "Usage: default_linemode [path=<regexp> | tag=<tag(s)>] <linemode>", bad=True)

        # Extract options like "path=..." or "tag=..." from the command line
        arg1 = self.arg(1)
        method = "always"
        argument = None
        if arg1.startswith("path="):
            method = "path"
            argument = re.compile(arg1[5:])
            self.shift()
        elif arg1.startswith("tag="):
            method = "tag"
            argument = arg1[4:]
            self.shift()

        # Extract and validate the line mode from the command line
        lmode = self.rest(1)
        if lmode not in FileSystemObject.linemode_dict:
            self.fm.notify(
                "Invalid linemode: %s; should be %s" % (
                    lmode, "/".join(FileSystemObject.linemode_dict)),
                bad=True,
            )

        # Add the prepared entry to the fm.default_linemodes
        entry = [method, argument, lmode]
        self.fm.default_linemodes.appendleft(entry)

        # Redraw the columns
        if self.fm.ui.browser:
            for col in self.fm.ui.browser.columns:
                col.need_redraw = True

    def tab(self, tabnum):
        return (self.arg(0) + " " + lmode
                for lmode in self.fm.thisfile.linemode_dict.keys()
                if lmode.startswith(self.arg(1)))


class quit(Command):  # pylint: disable=redefined-builtin
    """:quit

    Closes the current tab, if there's more than one tab.
    Otherwise quits if there are no tasks in progress.
    """
    def _exit_no_work(self):
        if self.fm.loader.has_work():
            self.fm.notify('Not quitting: Tasks in progress: Use `quit!` to force quit')
        else:
            self.fm.exit()

    def execute(self):
        if len(self.fm.tabs) >= 2:
            self.fm.tab_close()
        else:
            self._exit_no_work()


class quit_bang(Command):
    """:quit!

    Closes the current tab, if there's more than one tab.
    Otherwise force quits immediately.
    """
    name = 'quit!'
    allow_abbrev = False

    def execute(self):
        if len(self.fm.tabs) >= 2:
            self.fm.tab_close()
        else:
            self.fm.exit()


class quitall(Command):
    """:quitall

    Quits if there are no tasks in progress.
    """
    def _exit_no_work(self):
        if self.fm.loader.has_work():
            self.fm.notify('Not quitting: Tasks in progress: Use `quitall!` to force quit')
        else:
            self.fm.exit()

    def execute(self):
        self._exit_no_work()


class quitall_bang(Command):
    """:quitall!

    Force quits immediately.
    """
    name = 'quitall!'
    allow_abbrev = False

    def execute(self):
        self.fm.exit()


class delete(Command):
    """:delete

    Tries to delete the selection or the files passed in arguments (if any).
    The arguments use a shell-like escaping.

    "Selection" is defined as all the "marked files" (by default, you
    can mark files with space or v). If there are no marked files,
    use the "current file" (where the cursor is)

    When attempting to delete non-empty directories or multiple
    marked files, it will require a confirmation.
    """

    allow_abbrev = False
    escape_macros_for_shell = True

    def execute(self):
        import shlex
        from functools import partial

        def is_directory_with_files(path):
            return os.path.isdir(path) and not os.path.islink(path) and len(os.listdir(path)) > 0

        if self.rest(1):
            files = shlex.split(self.rest(1))
            many_files = (len(files) > 1 or is_directory_with_files(files[0]))
        else:
            cwd = self.fm.thisdir
            tfile = self.fm.thisfile
            if not cwd or not tfile:
                self.fm.notify("Error: no file selected for deletion!", bad=True)
                return

            # relative_path used for a user-friendly output in the confirmation.
            files = [f.relative_path for f in self.fm.thistab.get_selection()]
            many_files = (cwd.marked_items or is_directory_with_files(tfile.path))

        confirm = self.fm.settings.confirm_on_delete
        if confirm != 'never' and (confirm != 'multiple' or many_files):
            self.fm.ui.console.ask(
                "Confirm deletion of: %s (y/N)" % ', '.join(files),
                partial(self._question_callback, files),
                ('n', 'N', 'y', 'Y'),
            )
        else:
            # no need for a confirmation, just delete
            self.fm.delete(files)

    def tab(self, tabnum):
        return self._tab_directory_content()

    def _question_callback(self, files, answer):
        if answer == 'y' or answer == 'Y':
            self.fm.delete(files)


class mkdir(Command):
    """:mkdir <dirname>

    Creates a directory with the name <dirname>.
    """

    def execute(self):
        from os.path import join, expanduser, lexists
        from os import makedirs

        dirname = join(self.fm.thisdir.path, expanduser(self.rest(1)))
        if not lexists(dirname):
            makedirs(dirname)
        else:
            self.fm.notify("file/directory exists!", bad=True)

    def tab(self, tabnum):
        return self._tab_directory_content()


class touch(Command):
    """:touch <fname>

    Creates a file with the name <fname>.
    """

    def execute(self):
        from os.path import join, expanduser, lexists

        fname = join(self.fm.thisdir.path, expanduser(self.rest(1)))
        if not lexists(fname):
            open(fname, 'a').close()
        else:
            self.fm.notify("file/directory exists!", bad=True)

    def tab(self, tabnum):
        return self._tab_directory_content()


class edit(Command):
    """:edit <filename>

    Opens the specified file in neovim
    """

    def execute(self):
        if not self.arg(1):
            self.fm.edit_file(self.fm.thisfile.path)
        else:
            self.fm.edit_file(self.rest(1))

    def tab(self, tabnum):
        return self._tab_directory_content()


class rename(Command):
    """:rename <newname>

    Changes the name of the currently highlighted file to <newname>
    """

    def execute(self):
        from ranger.container.file import File
        from os import access

        new_name = self.rest(1)

        if not new_name:
            return self.fm.notify('Syntax: rename <newname>', bad=True)

        if new_name == self.fm.thisfile.relative_path:
            return None

        if access(new_name, os.F_OK):
            return self.fm.notify("Can't rename: file already exists!", bad=True)

        if self.fm.rename(self.fm.thisfile, new_name):
            file_new = File(new_name)
            self.fm.bookmarks.update_path(self.fm.thisfile.path, file_new)
            self.fm.tags.update_path(self.fm.thisfile.path, file_new.path)
            self.fm.thisdir.pointed_obj = file_new
            self.fm.thisfile = file_new

        return None

    def tab(self, tabnum):
        return self._tab_directory_content()


class help_(Command):
    """:help

    Display ranger's manual page.
    """
    name = 'help'

    def execute(self):
        def callback(answer):
            if answer == "q":
                return
            elif answer == "m":
                self.fm.display_help()
            elif answer == "c":
                self.fm.dump_commands()
            elif answer == "k":
                self.fm.dump_keybindings()
            elif answer == "s":
                self.fm.dump_settings()

        self.fm.ui.console.ask(
            "View [m]an page, [k]ey bindings, [c]ommands or [s]ettings? (press q to abort)",
            callback,
            list("mqkcs")
        )


class grep(Command):
    """:grep <string>

    Looks for a string in all marked files or directories
    """

    def execute(self):
        if self.rest(1):
            action = ['grep', '--line-number']
            action.extend(['-e', self.rest(1), '-r'])
            action.extend(f.path for f in self.fm.thistab.get_selection())
            self.fm.execute_command(action, flags='p')
