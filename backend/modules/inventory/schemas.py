from pydantic import BaseModel, ConfigDict

from typing import Optional, List

from uuid import UUID

from datetime import datetime









class IngredientBase(BaseModel):

    name: str

    unit: str

    stock_qty: float = 0

    alert_threshold: float = 0





class IngredientCreate(IngredientBase):

    pass





class IngredientUpdate(BaseModel):

    name: Optional[str] = None

    unit: Optional[str] = None

    stock_qty: Optional[float] = None

    alert_threshold: Optional[float] = None





class IngredientRead(IngredientBase):

    id: UUID

    created_at: datetime



    model_config = ConfigDict(from_attributes=True)









class BOMItemBase(BaseModel):

    variant_id: Optional[UUID] = None

    ingredient_id: UUID

    qty_required: float



class BOMItemCreate(BOMItemBase):

    pass



class BOMItemRead(BOMItemBase):

    id: UUID

    menu_item_id: UUID



    model_config = ConfigDict(from_attributes=True)



class MenuBOMUpdate(BaseModel):

    

    bom_items: List[BOMItemCreate]

