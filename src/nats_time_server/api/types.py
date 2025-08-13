from pyapi_service_kit.utils import TemplatedEnum
from ..config import Config


def _resolve_nats_subject(template: str) -> str:
    instance_id = Config().service_config.instance_id.lower()
    return template.format(instance_id=instance_id, guid=instance_id)


class ApiSubject(TemplatedEnum):
    TIME_SERVER_API = "{instance_id}.time-server"


ApiSubject.set_resolver(_resolve_nats_subject)
