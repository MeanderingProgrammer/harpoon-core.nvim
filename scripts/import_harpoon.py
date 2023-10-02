import json
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass(frozen=True)
class Project:
    root: Path
    branch: Optional[str]

    @property
    def name(self) -> str:
        result = [str(self.root)]
        if self.branch is not None:
            result.append(self.branch)
        return '-'.join(result)


def main() -> None:
    nvim_dir = Path.home().joinpath('.local/share/nvim')
    if not nvim_dir.is_dir():
        raise Exception(f'Could not find nvim directory: {nvim_dir}')

    harpoon = nvim_dir.joinpath('harpoon.json')
    if not harpoon.is_file():
        raise Exception(f'Could not find harpoon marks to import: {harpoon}')

    core = translate(json.loads(harpoon.read_text()))
    nvim_dir.joinpath('harpoon-core.json').write_text(json.dumps(core))
    print('Successfully migrated harpoon marks')


def translate(original: dict) -> dict:
    core = dict()
    for project, marks in original['projects'].items():
        project = resolve_project(project)
        if project is None:
            continue
        core_marks = []
        for mark in marks['mark']['marks']:
            core_mark = resolve_mark(project, mark)
            if core_mark is not None:
                core_marks.append(core_mark)
        if len(core_marks) > 0:
            core[project.name] = dict(marks=core_marks)
    return core


def resolve_project(project: str) -> Optional[Project]:
    parts = project.rsplit(sep='-', maxsplit=1)
    if len(parts) == 2:
        root = Path(parts[0])
        if root.is_dir():
            return Project(root=root, branch=parts[1])
    root = Path(project)
    return Project(root=root, branch=None) if root.is_dir() else None


def resolve_mark(project: Project, mark: dict) -> Optional[dict]:
    core_mark = None
    filename = mark['filename']
    if project.root.joinpath(filename).is_file():
        core_mark = dict(filename=filename)
        if 'row' in mark and 'col' in mark:
            core_mark['cursor'] = [int(mark['row']), int(mark['col'])]
    return core_mark


if __name__ == '__main__':
    main()
