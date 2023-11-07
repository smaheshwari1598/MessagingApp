import { LightningElement, track, api, wire } from 'lwc';
import getMessages from '@salesforce/apex/MessagingLWCController.getMessages';
import createMessage from '@salesforce/apex/MessagingLWCController.createMessage';
import getRecordDetails from '@salesforce/apex/MessagingLWCController.getRecordDetails';
import insertAttachments from '@salesforce/apex/MessagingLWCController.calloutToS3';
import { refreshApex } from '@salesforce/apex';
import { subscribe} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MessagingApp extends LightningElement {
    
    inputValue='';
    wiredMessagesResult;
    subscription = {};
    error;
    @api recordId;
    @api fileName='';
    @api fileData='';
    @api fileType='';
    @api channelName = '/event/NewMessage__e';
    @api offSetVal='';
    @track messagesWrapper = [];
    @track contactName;
    @track isLoading = false;
    @track imageDataUrl=[];
    @api objectApiName;
    @track showSpinner = true;
    @track fileContents=[];
    
    connectedCallback(){
        this.handleSubscribe();
    }

    //checks whether show Send Button Enabled or Disabled
    get sendButtonClass() {
        return (this.inputValue.trim() == '' && this.fileContents.length < 1) ? true : false;
    }

    // Method to get the Messages record related to Contact
    @wire(getMessages,{ recordId: '$recordId' , offSetValFromUI : '',objectApiName: '$objectApiName'}) 
    messageRecs(response) {
        if (response.data) {
            this.showSpinner = false;
            this.wiredMessagesResult = response;
            this.messagesWrapper = response.data.messageWithAttachments;
            this.contactName = response.data.contactPersonName;
            this.offSetVal = response.data.defaultOffSet;
            setTimeout(() => {
                this.scrollToBottom();
            }, 500);
        } else if (response.error){
            console.log('error : ',error);
        }
    }

    // Method to get the input which User Entered
    handleInputChange(event) {
        this.inputValue = event.target.value;
    }

    // Called when User Clicks on Send Icon Button
    handleSendClick() {
        console.log('In handleSendClick----');
        if(/\(|\)/.test(this.fileName)){
            this.inputValue = '';
            this.fileData = '';
            this.fileName  = '';
            this.fileType = '';
            console.log('Cannot contain bracket');
        }else{
            this.createMessageRecord()
            .then(result => {
                console.log('In createMessageRecord result---',JSON.stringify(result));
                this.inputValue = '';
                this.imageDataUrl='';
                return this.createAttachmentsRecords(result);
            })
            .then(result => {
                const toastEvent = new ShowToastEvent({
                    title: 'Success',
                    message: 'Second method completed successfully',
                    variant: 'success',
                });
                this.dispatchEvent(toastEvent);
            })
            .catch(error => {
                console.error('Error: ' + error);
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'An error occurred',
                    variant: 'error',
                });
                this.dispatchEvent(toastEvent);
            });
            this.imageDataUrl = '';
        }
    }

    createMessageRecord(){
        return new Promise((resolve, reject) => {
            createMessage({ messageBody: this.inputValue, recordId: this.recordId, fileContents : this.fileContents, objectApiName: this.objectApiName})
            .then(result => {
                    refreshApex(this.wiredMessagesResult);
                    resolve(result);
                })
                .catch(error => {
                    reject(error);
                });
        });
    }

    createAttachmentsRecords(messageRecordId) {
        return new Promise((resolve, reject) => {
            insertAttachments({ recordId: this.recordId, fileContents : this.fileContents, objectApiName: this.objectApiName,messageRecId: messageRecordId })
                .then(result => {
                    this.fileContents = [];
                    resolve(result);
                })
                .catch(error => {
                    reject(error);
                });
        });
    }


    // JavaScript function to scroll to the bottom of the chat container
    scrollToBottom() {
        const chatListWrapper = this.template.querySelector('.slds-chat-list-container');
        if (chatListWrapper) {
            chatListWrapper.scrollTop = chatListWrapper.scrollHeight;
        }
    }

    // Calling Apex Method to Load More Messages when scrollBar moves
    loadMoreMessages() {
        const scrollContainer = this.template.querySelector('.slds-chat-list-container');
        if (scrollContainer.scrollTop < 250 && !this.isLoading) {
            this.isLoading = true;
            let newOffSetVal = parseInt(this.offSetVal) - 5;
            getMessages({ recordId: this.recordId , offSetValFromUI : newOffSetVal, objectApiName: this.objectApiName})
            .then((result) => {
                this.messagesWrapper = this.createMessageData(result.messageWithAttachments);
                this.offSetVal = result.defaultOffSet;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch((error) => {
                this.error = error;
                this.messagesWrapper = undefined;
            });
        }
    }
    
    createMessageData(messageData) {
        let messageWrapperList=[];
        messageData.forEach(item => {
            const messageRecord = {
                messageRec: item.messageRec,
            };
           
            if (item.attachmentLinks != null && item.attachmentLinks != 'undefined') {
                messageRecord.attachmentLinks = item.attachmentLinks;
            }
            messageWrapperList.push(messageRecord);
            console.log('messageRec--' + JSON.stringify(messageRecord));
        });
        return messageWrapperList;
    }
    
    
    // Handles when any new incoming records pops up
    handleSubscribe() {
        const self = this;
        let phoneNumberFieldValue = '';
        getRecordDetails({ recordId: this.recordId, objectApiName: this.objectApiName})
        .then((result) => {
            phoneNumberFieldValue = result.Phone;
        })
        .catch(error => {
            console.error(error)
        });
        const messageCallback = function (response) {
            var obj = JSON.parse(JSON.stringify(response));
            let objData = obj.data.payload;
            if((JSON.stringify(phoneNumberFieldValue)).trim().replace(/"/g, '') == obj.data.payload.Recipient__c ||
            (JSON.stringify(phoneNumberFieldValue)).trim().replace(/"/g, '') == obj.data.payload.Sender__c){
                refreshApex(self.wiredMessagesResult);
            }    
        };
 
        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    triggerFileInput() {
        const fileInput = this.template.querySelector('input[type="file"]');
        fileInput.click();
    }
    
    handleFileUpload(event) {
        const files = event.target.files;
        
        if (files && files.length > 0) {
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                const reader = new FileReader();
    
                reader.onload = (event) => {
                    this.imageDataUrl.push(event.target.result);
                    console.log('this.ImageUrl---', this.imageDataUrl);
                    this.fileContents.push({
                        fileName: file.name,
                        fileData: event.target.result.split(',')[1],
                        fileType: file.type
                    });
                };
                reader.readAsDataURL(file);
            }
        }
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }
}