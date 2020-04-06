<?php

class Seuf_Catalog_Block_Product_Renderer_Delete extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract{
    
    public function render(Varien_Object $row){
       
        return "<form id='delete_product_".$row->getData($this->getColumn()->getIndex())."' method='POST' action='".Mage::helper('adminhtml')->getUrl("uberedit/adminhtml_edit/deleteProduct")."'>
                    <input type='hidden' value='".$row->getData($this->getColumn()->getIndex())."' name='id'/>
                    <input type='hidden' name='form_key' value='".Mage::getSingleton('core/session')->getFormKey()."'/>
                    
                </form>
                <button class='delete' onclick='deleteProduct(".$row->getData($this->getColumn()->getIndex()).")' type='button'>Slet</button>
";
        
    }
}