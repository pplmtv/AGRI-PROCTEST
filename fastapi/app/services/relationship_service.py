# relationship_service.py
from typing import List, Dict
from boto3.dynamodb.conditions import Key
from app.db import relationship_table

def get_accessible_farmer_ids(user: Dict) -> List[str]:
    """
    Returns farmer_id list that this user can view.

    - farmer: [self]
    - family: relationship_table query by family_id (=sub)
    - admin: for now, [self] (keep simple); later can be expanded.
    """
    role = user.get("role")
    sub = user.get("sub")

    if not role or not sub:
        return []

    if role == "farmer":
        return [sub]

    if role == "family":
        resp = relationship_table.query(
            KeyConditionExpression=Key("family_id").eq(sub),
            ProjectionExpression="farmer_id",
        )
        items = resp.get("Items", [])
        # dedupe + stable order
        farmer_ids = []
        seen = set()
        for it in items:
            fid = it.get("farmer_id")
            if fid and fid not in seen:
                seen.add(fid)
                farmer_ids.append(fid)
        return farmer_ids

    if role == "admin":
        # シンプル版: adminは「まず自分」だけ（ここは後で拡張）
        return [sub]

    return []
