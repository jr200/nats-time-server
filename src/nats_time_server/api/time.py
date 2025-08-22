from nats.aio.client import Client as NATS

from ..config import Config
from pyapi_service_kit.nats import NatsPayload


async def service_time_utc_task(nc: NATS, subject: str, _counter: int):
    t = Config().app_config.now_utc()
    if Config().app_config.publish_iso8601_time:
        extra = {"time_utc": t.isoformat()}
    else:
        extra = None

    payload = NatsPayload(type="epoch_ms", data=t, extra=extra)

    await nc.publish(subject, payload.as_bytes())
