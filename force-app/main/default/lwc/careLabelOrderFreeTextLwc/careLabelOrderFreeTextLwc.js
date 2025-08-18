import { LightningElement,api,track,wire} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import {fireEvent} from 'c/pubsub';


export default class CareLabelOrderFreeTextLwc extends LightningElement {
   
   @api StyleNumber;@api RNNumberl;@api LotNumber;@api SupplierNumber;@api LabellingCode;
   @api PackagingCode;@api SeasonMonth;  @api SeasonYear;@api ItemNumber;@api careinstruct;
  @api freeTextId;
  @track StyleNumber;@track RNNumberl;@track LotNumber;@track SupplierNumber;@track LabellingCode;
  @track PackagingCode;@track SeasonMonth;@track SeasonYear;@track ItemNumber;@track careinstruct;
 @track freeTextId;@api month;@track month;
   //api from carelabel
    @api isFreetextmodal; @api itemMaster='Item_Master__c';@api freetextData ={};@api viewFreetextData ={};
    @track freetextData={};@track viewFreetextData={};

   connectedCallback(){
    // console.log('StyleNumber -->'+JSON.stringify(this.StyleNumber));
    // console.log('RNNumberl -->'+JSON.stringify(this.RNNumberl));
    // console.log('SeasonYear -->'+JSON.stringify(this.SeasonYear));
    // console.log('SupplierNumber -->'+JSON.stringify(this.SupplierNumber));
    // console.log('careinstruct -->'+JSON.stringify(this.careinstruct));
    // console.log('SeasonMonth -->'+JSON.stringify(this.SeasonMonth));
    // console.log('month -->'+JSON.stringify(this.month));
   }
    onStyleNumber(event){
        this.StyleNumber =event.target.value;
        this.viewFreetextDatas();
      
    }
    onRNNumber(event){
        this.RNNumber =event.target.value;
        this.viewFreetextDatas();

    }
    onLotNumber(event){
        this.LotNumber =event.target.value;
        this.viewFreetextDatas();
       
    }
    onSupplierNumber(event){
        this.SupplierNumber =event.target.value;
       
    }
    onLabellingCode(event){
        this.LabellingCode =event.target.value;
        this.viewFreetextDatas();
        
    }
    onPackagingCode(event){
        this.PackagingCode =event.target.value;
        this.viewFreetextDatas();
       
    }
    onSeasonMonth(event){
        this.SeasonMonth =event.target.value;
        this.viewFreetextDatas();
        
    }
    onSeasonYear(event){
        this.SeasonYear =event.target.value;
        this.viewFreetextDatas();
       
    }
    onItemNumber(event){
        this.ItemNumber =event.target.value;
        this.viewFreetextDatas();
      

    }
    oncareinstruction(event){
        this.careinstruct =event.target.value;
        this.viewFreetextDatas();
       
    }

    @wire(CurrentPageReference) pageRef;
    onblurFreeText(){
        fireEvent(this.pageRef,"changeTabColorFreeText");
       
        var FreeText=[];
        var item = {
            StyleNumber:  this.StyleNumber,
            RNNumber:  this.RNNumber,
            LotNumber:  this.LotNumber,
            Careinstructions:  this.careinstruct,
            SupplierNumber:  this.SupplierNumber,
            LabellingCode:  this.LabellingCode,
            PackagingCode: this.PackagingCode,
            SeasonMonth:  this.SeasonMonth,
            SeasonYear:  this.SeasonYear,
            ItemNumber: this.ItemNumber,
                };
        FreeText.push(item);
        // console.log('FreeText -->'+JSON.stringify(FreeText));
        var obj={FreeTextkey:FreeText};
        // console.log('FreeTextKey-->'+JSON.stringify(obj));
        fireEvent(this.pageRef,"loadMyEvent",obj);

    }
    @api
    FreetextData(){
        alert('inside freetext  data');
        var freetextData=new Object();
        freetextData.freeTextId=this.freeTextId;
        freetextData.StyleNumber=this.StyleNumber;
        freetextData.RNNumber=this.RNNumber;
        freetextData.LotNumber=this.LotNumber;
        freetextData.careinstruct=this.careinstruct;
        freetextData.SupplierNumber=this.SupplierNumber;
        freetextData.LabellingCode=this.LabellingCode;
        freetextData.PackagingCode=this.PackagingCode;
        freetextData.SeasonMonth=this.SeasonMonth;
        freetextData.SeasonYear=this.SeasonYear;
        freetextData.ItemNumber=this.ItemNumber;
        this.freetextData =freetextData;

        const freetextDatas = new CustomEvent('freetextdata', {
            detail: {'freetextData':this.freetextData}
        });
        this.dispatchEvent(freetextDatas);    
    }
  //  @api 
    viewFreetextDatas(){
        var freetextData=new Object();
        freetextData.freeTextId=this.freeTextId;
        freetextData.StyleNumber=this.StyleNumber;
        freetextData.RNNumber=this.RNNumber;
        freetextData.LotNumber=this.LotNumber;
        freetextData.careinstruct=this.careinstruct;
        freetextData.SupplierNumber=this.SupplierNumber;
        freetextData.LabellingCode=this.LabellingCode;
        freetextData.PackagingCode=this.PackagingCode;
        freetextData.SeasonMonth=this.SeasonMonth;
        freetextData.SeasonYear=this.SeasonYear;
        freetextData.ItemNumber=this.ItemNumber;
        this.viewFreetextData =freetextData;
        // console.log('viewFreetextData -->'+JSON.stringify(this.viewFreetextData));
        const viewFreetextData = new CustomEvent('viewfreetextdata', {
            detail: {'viewFreetextData':this.viewFreetextData}
        });
        this.dispatchEvent(viewFreetextData); 

        var obj={FreeTextkey:freetextData};
        // console.log('FreeTextKey-->'+JSON.stringify(obj.FreeTextkey));
        fireEvent(this.pageRef,"loadMyEvent",obj);
    }
    @api
    clearData() {
        
        this.StyleNumber ='';
        this.RNNumber ='';
        this.LotNumber ='';
        this.careinstruct ='';
        this.SupplierNumber ='';
        this.LabellingCode ='';
        this.PackagingCode ='';
        this.SeasonMonth ='';
        this.SeasonYear ='';
        this.ItemNumber ='';

    }



}