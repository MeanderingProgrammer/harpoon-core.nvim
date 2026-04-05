import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

Config = dict[str, Any]


@dataclass(frozen=True)
class Project:
    root: Path
    branch: str | None

    @property
    def name(self) -> str:
        if self.branch is None:
            return str(self.root)
        else:
            return f"{self.root}-{self.branch}"


def main() -> None:
    nvim = Path.home() / ".local/share/nvim"
    assert nvim.is_dir(), f"No nvim directory: {nvim}"

    harpoon = nvim / "harpoon.json"
    assert harpoon.is_file(), f"No harpoon marks file to import from: {harpoon}"

    core = translate(json.loads(harpoon.read_text()))
    (nvim / "harpoon-core.json").write_text(json.dumps(core))
    print("Successfully migrated harpoon marks")


def translate(harpoon: Config) -> Config:
    result: Config = dict()
    for project, config in harpoon["projects"].items():
        project = resolve_project(project)
        if project is None:
            continue
        marks: list[Config] = []
        for mark in config["mark"]["marks"]:
            mark = resolve_mark(project, mark)
            if mark is not None:
                marks.append(mark)
        if len(marks) > 0:
            result[project.name] = dict(marks=marks)
    return result


def resolve_project(project: str) -> Project | None:
    parts = project.rsplit(sep="-", maxsplit=1)
    if len(parts) == 2:
        root = Path(parts[0])
        if root.is_dir():
            return Project(root=root, branch=parts[1])
    root = Path(project)
    return Project(root=root, branch=None) if root.is_dir() else None


def resolve_mark(project: Project, mark: Config) -> Config | None:
    filename = mark["filename"]
    if not (project.root / filename).is_file():
        return None
    result = dict(filename=filename)
    row, col = mark.get("row"), mark.get("col")
    if row is not None and col is not None:
        result["cursor"] = [int(row), int(col)]
    return result


if __name__ == "__main__":
    main()
