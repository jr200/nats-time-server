from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Dict, Mapping, ClassVar
from polars_hist_db.config.helpers import load_yaml, get_nested_key
import pytz


@dataclass
class ServiceConfig:
    instance_id: str

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ServiceConfig":
        return cls(**data)


@dataclass
class AppConfig:
    clock_start_utc: datetime
    clock_increment: timedelta
    tick_frequency: timedelta
    allow_future_time: bool
    _started_time_utc: datetime = field(
        default_factory=lambda: datetime.now(pytz.timezone("UTC"))
    )

    def now_utc(self) -> datetime:
        now_utc = datetime.now(pytz.timezone("UTC"))
        if self.clock_start_utc is None:
            return now_utc

        elapsed_seconds = (now_utc - self._started_time_utc).total_seconds()
        tf = self.tick_frequency.total_seconds()
        ticks = int(elapsed_seconds / tf) if tf > 0 else 0
        proposed = self.clock_start_utc + self.clock_increment * ticks

        if proposed > now_utc:
            if not self.allow_future_time:
                return now_utc

        return proposed

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "AppConfig":
        def _parse_utc(dt_value: Any) -> datetime:
            if isinstance(dt_value, datetime):
                return dt_value
            if isinstance(dt_value, str):
                value = dt_value.strip()
                if value.endswith("Z"):
                    value = value[:-1] + "+00:00"
                return datetime.fromisoformat(value)
            raise TypeError("clock_start_utc must be a datetime or ISO string")

        def _parse_duration(value: Any) -> timedelta:
            if isinstance(value, timedelta):
                return value
            if isinstance(value, str):
                s = value.strip().lower()
                if s.endswith("ms"):
                    return timedelta(milliseconds=float(s[:-2]))
                if s.endswith("s"):
                    return timedelta(seconds=float(s[:-1]))
                if s.endswith("m"):
                    return timedelta(minutes=float(s[:-1]))
                if s.endswith("h"):
                    return timedelta(hours=float(s[:-1]))

            raise TypeError("duration must be timedelta or string with unit (ms|s|m|h)")

        return cls(
            clock_start_utc=_parse_utc(data["clock_start_utc"]),
            clock_increment=_parse_duration(data["clock_increment"]),
            tick_frequency=_parse_duration(data["tick_frequency"]),
            allow_future_time=bool(data["allow_future_time"]),
        )


@dataclass
class Config:
    _borg: ClassVar[Dict[str, Any]] = {}

    # for auto-complete
    nats_config: Dict[str, Any]
    service_config: ServiceConfig
    app_config: AppConfig

    def __init__(self):
        self.__dict__ = self._borg

    @classmethod
    def from_yaml(
        cls,
        filename: str,
        nats_config_path: str = "nats",
        service_config_path: str = "service",
        app_config_path: str = "app",
    ) -> "Config":
        yaml_doc: Mapping[str, Any] = load_yaml(filename)

        nats_config = get_nested_key(yaml_doc, nats_config_path.split("."))

        raw_service_config = get_nested_key(yaml_doc, service_config_path.split("."))
        service_config = ServiceConfig.from_dict(raw_service_config)

        raw_app_config = get_nested_key(yaml_doc, app_config_path.split("."))
        app_config = AppConfig.from_dict(raw_app_config)

        # Populate the _borg state directly since this is a classmethod
        cls._borg = {
            "nats_config": nats_config,
            "service_config": service_config,
            "app_config": app_config,
            "config_filename": filename,
        }

        return cls()
