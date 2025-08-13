import asyncio
from typing import List

from nats.aio.client import Client as NATS
from pyapi_service_kit.nats import periodic_publisher_task

from .api.types import ApiSubject
from .api.time import service_time_utc_task
from .config import Config


async def register_tasks(nc: NATS, tasks: List[asyncio.Task]):
    tasks.append(
        asyncio.create_task(
            periodic_publisher_task(
                nc,
                ApiSubject.TIME_SERVER_API.resolved,
                Config().app_config.tick_frequency,
                cb=service_time_utc_task,
            ),
            name=ApiSubject.TIME_SERVER_API.resolved,
        )
    )
