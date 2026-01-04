#!/usr/bin/python3
"""
Ansible module to select reachable IPs from grouped lists
and randomly choose one IP per group.
"""

from ansible.module_utils.basic import AnsibleModule
from typing import List
import subprocess
import random
import datetime
import yaml
import logging
from pathlib import Path


LOG_FILE = Path("error.log")
OUTPUT_FILE = Path("apics.txt")


class ApicSelector:
    """
    Handles loading IP groups, connectivity checks,
    random selection, and output persistence.
    """

    def __init__(
        self,
        source_file: Path,
        ping_count: int,
        ping_timeout: int,
        persist_files: bool,
    ):
        self.source_file = source_file
        self.ping_count = ping_count
        self.ping_timeout = ping_timeout
        self.persist_files = persist_files
        self.today = datetime.date.today().isoformat()

        self.reachable_groups: List[List[str]] = []
        self.selected_ips: List[str] = []

    def load_ip_groups(self) -> List[List[str]]:
        """Load list of IP groups from YAML file."""
        if not self.source_file.exists():
            raise FileNotFoundError(f"{self.source_file} not found")

        with self.source_file.open() as f:
            data = yaml.safe_load(f)

        if not isinstance(data, list):
            raise ValueError("YAML file must contain a list of lists")

        return data

    def ping(self, ip: str) -> bool:
        """Check IP reachability using ping."""
        cmd = [
            "ping",
            "-c",
            str(self.ping_count),
            "-W",
            str(self.ping_timeout),
            ip,
        ]
        result = subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return result.returncode == 0

    def evaluate_reachability(self, groups: List[List[str]]) -> None:
        """Determine reachable IPs for each group."""
        for group in groups:
            reachable = [ip for ip in group if self.ping(ip)]
            self.reachable_groups.append(reachable)

    def select_random_ips(self) -> None:
        """Select one random reachable IP per group."""
        for group in self.reachable_groups:
            if group:
                self.selected_ips.append(random.choice(group))

    def persist_results(self) -> None:
        """Persist output and logs if enabled."""
        if not self.persist_files:
            return

        if not self.selected_ips:
            LOG_FILE.write_text(
                f"{self.today} - Failed to reach any APIC\n",
                encoding="utf-8",
            )
        else:
            OUTPUT_FILE.write_text(
                " ".join(self.selected_ips),
                encoding="utf-8",
            )

    def run(self) -> List[str]:
        """Main execution path."""
        groups = self.load_ip_groups()
        self.evaluate_reachability(groups)
        self.select_random_ips()
        self.persist_results()
        return self.selected_ips


def main():
    module = AnsibleModule(
        argument_spec=dict(
            source_file=dict(type="path", default="list_of_lists.yml"),
            ping_count=dict(type="int", default=2),
            ping_timeout=dict(type="int", default=1),
            persist_files=dict(type="bool", default=True),
        ),
        supports_check_mode=True,
    )

    if module.check_mode:
        module.exit_json(changed=False, msg="Check mode: no action taken")

    try:
        selector = ApicSelector(
            source_file=Path(module.params["source_file"]),
            ping_count=module.params["ping_count"],
            ping_timeout=module.params["ping_timeout"],
            persist_files=module.params["persist_files"],
        )

        selected = selector.run()

        module.exit_json(
            changed=bool(selected),
            apics=selected,
            count=len(selected),
        )

    except Exception as exc:
        module.fail_json(msg=str(exc))


if __name__ == "__main__":
    main()
