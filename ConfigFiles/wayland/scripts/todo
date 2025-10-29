#!/usr/bin/env python3
import curses, json
from pathlib import Path

# Config
COLUMNS = ["To-Do", "Doing", "Done"]
DATA_DIR = Path.home() / ".local" / "share" / "todo"
SAVE_FILE = DATA_DIR / "board.json"
DATA_DIR.mkdir(parents=True, exist_ok=True)

def load_board():
    if SAVE_FILE.exists():
        try:
            return json.loads(SAVE_FILE.read_text())
        except Exception:
            pass
    return {col: [] for col in COLUMNS}

def save_board(board):
    try:
        SAVE_FILE.write_text(json.dumps(board, indent=2))
    except Exception:
        pass

def clamp_index(board, col_idx, desired_row):
    n = len(board[COLUMNS[col_idx]])
    if n == 0:
        return 0, desired_row
    task_idx = max(0, min(desired_row, n - 1))
    return task_idx, desired_row

def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()

    curses.init_pair(1, curses.COLOR_WHITE, -1)   # normal text
    curses.init_pair(2, curses.COLOR_CYAN, -1)    # status line
    curses.init_pair(3, curses.COLOR_GREEN, -1)   # column titles
    curses.init_pair(4, curses.COLOR_YELLOW, -1)  # move mode highlight

    stdscr.nodelay(False)

    board = load_board()
    col_idx = 0
    desired_row = 0
    task_idx, desired_row = clamp_index(board, col_idx, desired_row)

    move_mode, held_task = False, None

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        col_width = max(20, w // len(COLUMNS))

        # Draw columns with vertical separators
        for i, col in enumerate(COLUMNS):
            x = i * col_width
            try:
                stdscr.addstr(0, x + 1, col.center(col_width - 2),
                              curses.color_pair(3) | curses.A_BOLD | curses.A_UNDERLINE)
            except curses.error:
                pass

            n = len(board[col])
            max_rows = max(n, desired_row + 1)
            for j in range(max_rows):
                if j < n:
                    text = f" {board[col][j]}"
                else:
                    text = " "
                attr = curses.color_pair(1)
                if i == col_idx and j == task_idx:
                    if move_mode:
                        attr = curses.color_pair(4) | curses.A_REVERSE | curses.A_BOLD
                    else:
                        attr |= curses.A_REVERSE
                try:
                    stdscr.addnstr(j + 2, x + 1, text.ljust(col_width - 2), col_width - 2, attr)
                except curses.error:
                    pass

            if i < len(COLUMNS) - 1:
                for y in range(1, h - 3):
                    try:
                        stdscr.addch(y, x + col_width, '|', curses.color_pair(2))
                    except curses.error:
                        pass

        status = "-- MOVE MODE -- press m to drop" if move_mode \
                 else "[a] Add  [d] Delete  [hjkl] Navigate  [m] Move  [q] Quit"
        try:
            stdscr.addstr(h - 2, 1, status.center(w - 2), curses.color_pair(2) | curses.A_BOLD)
        except curses.error:
            pass

        key = stdscr.getch()
        if key == ord('q'):
            break
        elif key == ord('l') and col_idx < len(COLUMNS) - 1:
            col_idx += 1
            task_idx, desired_row = clamp_index(board, col_idx, desired_row)
        elif key == ord('h') and col_idx > 0:
            col_idx -= 1
            task_idx, desired_row = clamp_index(board, col_idx, desired_row)
        elif key == ord('j'):
            desired_row += 1
            task_idx, desired_row = clamp_index(board, col_idx, desired_row)
        elif key == ord('k'):
            desired_row = max(0, desired_row - 1)
            task_idx, desired_row = clamp_index(board, col_idx, desired_row)
        elif key == ord('m'):
            if not move_mode and len(board[COLUMNS[col_idx]]) > 0:
                held_task = board[COLUMNS[col_idx]].pop(task_idx)
                move_mode = True
                task_idx, desired_row = clamp_index(board, col_idx, desired_row)
            elif move_mode:
                insert_pos = task_idx + 1 if len(board[COLUMNS[col_idx]]) > 0 else 0
                board[COLUMNS[col_idx]].insert(insert_pos, held_task)
                held_task, move_mode = None, False
                desired_row = insert_pos
                task_idx, desired_row = clamp_index(board, col_idx, desired_row)
        elif not move_mode and key == ord('a'):
            curses.echo()
            try:
                stdscr.addstr(h - 1, 1, "New task: ", curses.color_pair(2))
                task = stdscr.getstr(h - 1, 11).decode()
            finally:
                curses.noecho()
            if task:
                board[COLUMNS[col_idx]].append(task)
                task_idx, desired_row = clamp_index(board, col_idx, desired_row)
        elif not move_mode and key == ord('d'):
            if len(board[COLUMNS[col_idx]]) > 0:
                board[COLUMNS[col_idx]].pop(task_idx)
                task_idx, desired_row = clamp_index(board, col_idx, desired_row)

        save_board(board)

if __name__ == "__main__":
    curses.wrapper(main)

