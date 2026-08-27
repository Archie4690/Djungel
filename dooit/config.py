from dooit.api import Todo
from dooit.ui.api import DooitAPI, subscribe
from dooit.ui.api.events import Startup, WorkspaceSelected
from dooit.api.theme import DooitThemeBase
from dooit.ui.api.widgets import TodoWidget
from rich.style import Style
from dooit_extras.formatters import *
from dooit_extras.bar_widgets import *
from dooit_extras.scripts import *
from dooit.ui.widgets.trees import WorkspacesTree, TodosTree
from rich.text import Text

def toggle_workspaces(api: DooitAPI):
    def wrapper():
        workspace_switcher = api.app.screen.query_one("#workspace_switcher")
        todo_switcher = api.app.screen.query_one("#todo_switcher")

        if workspace_switcher.display:
            workspace_switcher.display = False
            todo_switcher.styles.column_span = 2
            api.switch_focus()
        else:
            workspace_switcher.display = True
            todo_switcher.styles.column_span = 1
            api.app.workspace_tree.focus()

    return wrapper

@subscribe(Startup)
def setup(api: DooitAPI, _):
    api.keys.set("<ctrl+b>", toggle_workspaces(api))

    def on_l():
        tree = api.app.focused
        if isinstance(tree, WorkspacesTree):
            api.switch_focus()
        elif tree.highlighted is not None and not tree.is_node_expaned(tree.node.id):
            api.toggle_expand()

    def on_h():
        tree = api.app.focused
        if tree.highlighted is not None and tree.is_node_expaned(tree.node.id):
            api.toggle_expand()
        elif isinstance(tree, TodosTree):
            api.switch_focus()

    api.keys.set("l", on_l)
    api.keys.set("h", on_h)

    # dd = delete without confirmation; D = edit due (d alone is shadowed by dd)
    api.vars.show_confirm = False
    api.keys.set("dd", api.remove_node)
    api.keys.set("D", api.edit_due)

    # O and A both add a child node
    api.keys.set("O", api.add_child_node)

    _show_completed = [False]

    def apply_completed_visibility(tree):
        if not isinstance(tree, TodosTree):
            return
        for option in tree._options:
            model = tree._renderers[option.id].model
            if model.is_completed:
                if _show_completed[0]:
                    tree.enable_option(option.id)
                else:
                    tree.disable_option(option.id)

    def toggle_complete():
        api.toggle_complete()
        if not _show_completed[0]:
            tree = api.app.focused
            if isinstance(tree, TodosTree) and tree.highlighted is not None:
                if tree.current_model.is_completed:
                    tree.disable_option(tree.node.id)

    def toggle_show_completed():
        _show_completed[0] = not _show_completed[0]
        tree = api.app.focused
        apply_completed_visibility(tree)

    api.keys.set(" ", toggle_complete)
    api.keys.set("C", toggle_show_completed)

    # o adds a sibling (like vim); a stays as add_sibling (default)
    api.keys.set("o", api.add_sibling)

    # urgency: = / + increase, - / _ decrease, clamped to 1-4
    def increase_urgency():
        tree = api.app.focused
        if isinstance(tree, TodosTree) and tree.current_model.urgency < 4:
            api.increase_urgency()

    def decrease_urgency():
        tree = api.app.focused
        if isinstance(tree, TodosTree) and tree.current_model.urgency > 1:
            api.decrease_urgency()

    api.keys.set(["=", "+"], increase_urgency)
    api.keys.set(["-", "_"], decrease_urgency)

    @subscribe(WorkspaceSelected)
    def on_workspace_selected(api: DooitAPI, _):
        def apply():
            tree = api.vars.todos_tree
            if tree:
                apply_completed_visibility(tree)
        api.app.call_after_refresh(apply)


class DooitThemeCatppuccin(DooitThemeBase):
    _name: str = "dooit-gruvbox"

    # background colors
    background1: str = "#1c1c1c"  # Darkest
    background2: str = "#282828"
    background3: str = "#504945"  # Lightest

    # foreground colors
    foreground1: str = "#a89984"  # Lightest
    foreground2: str = "#d5c4a1"
    foreground3: str = "#ebdbb2"  # Brightest

    # other colors
    red: str = "#fb4934"
    orange: str = "#fe8019"
    yellow: str = "#fabd2f"
    green: str = "#b8bb26"
    blue: str = "#83a598"
    purple: str = "#d3869b"
    magenta: str = "#b16286"
    cyan: str = "#8ec07c"

    # accent colors
    primary: str = yellow
    secondary: str = blue


@subscribe(Startup)
def setup_colorscheme(api: DooitAPI, _):
    api.css.set_theme(DooitThemeCatppuccin)
    dim_unfocused(api)


@subscribe(Startup)
def setup_formatters(api: DooitAPI, _):
    fmt = api.formatter
    theme = api.vars.theme

    # ------- WORKSPACES -------
    format = Text(" ({}) ", style=theme.primary).markup
    fmt.workspaces.description.add(description_children_count(format))

    # --------- TODOS ---------
    # status formatter
    fmt.todos.status.add(status_icons(completed=" ", pending=" ", overdue=" "))

    # urgency formatte
    u_icons = {1: "  󰯬", 2: "  󰯯", 3: "  󰯲", 4: "  󰯵"}
    fmt.todos.urgency.add(urgency_icons(icons=u_icons))

    # due formatter
    fmt.todos.due.add(due_casual_format())
    fmt.todos.due.add(due_icon(completed="󱫐 ", pending="󱫚 ", overdue="󱫦 "))

    # description formatter
    format = Text("  {completed_count}/{total_count}", style=theme.green).markup
    fmt.todos.description.add(todo_description_progress(fmt=format))
    fmt.todos.description.add(description_highlight_tags(fmt=" {}"))
    fmt.todos.description.add(description_strike_completed())


@subscribe(Startup)
def setup_layout(api: DooitAPI, _):
    api.layouts.todo_layout = [
        TodoWidget.status,
        TodoWidget.urgency,
        TodoWidget.description,
        TodoWidget.due,
        TodoWidget.recurrence,
    ]


@subscribe(Startup)
def setup_bar(api: DooitAPI, _):
    theme = api.vars.theme

    widgets = [
        CurrentWorkspace(api, fmt=" 󰄛 {} ", bg=theme.magenta),
        Spacer(api, width=1),
        Mode(api, format_normal=" 󰷸 NORMAL ", format_insert=" 󰛿 INSERT "),
        Spacer(api, width=0),
        Clock(api, fmt=" 󰃰 {} ", format="%H:%M"),
        Spacer(api, width=1),
        Date(api, fmt=" 󰃯 {} "),
    ]
    api.bar.set(widgets)


@subscribe(Startup)
def setup_dashboard(api: DooitAPI, _):
    theme = api.vars.theme

    ascii_art = r"""
   ,-.       _,---._ __  / \
 /  )    .-'       `./ /   \
(  (   ,'            `/    /|
 \  `-"             \'\   / |
  `.              ,  \ \ /  |
   /`x          ,'-`----Y   |
  (            ;        |   '
  |  ,-.    ,-'         |  /
  |  | (   |      TODOS | /
  )  |  \  `.___________|/
  `--'   `--'
    """

    ascii_art = Text(ascii_art, style=theme.primary)
    ascii_art.highlight_words(["TODOS"], style=theme.red)

    due_today = sum([1 for i in Todo.all() if i.is_due_today and i.is_pending])
    overdue = sum([1 for i in Todo.all() if i.is_overdue])

    header = Text(
        "Another day, another opportunity to organize my todos and then procrastinate",
        style=Style(color=theme.secondary, bold=True, italic=True),
    )

    items = [
        header,
        ascii_art,
        "",
        "",
        Text("󰠠 Tasks pending today: {}".format(due_today), style=theme.green),
        Text("󰁇 Tasks still overdue: {}".format(overdue), style=theme.red),
    ]
    api.dashboard.set(items)
