import { LightningElement, track, api, wire } from 'lwc';
import getMessages from '@salesforce/apex/MessagingLWCController.getMessages';
import createMessage from '@salesforce/apex/MessagingLWCController.createMessage';
import { refreshApex } from '@salesforce/apex';
import { subscribe} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';

const MAX_FILE_SIZE = 100000000; //10mb 
export default class MessagingLWC extends LightningElement {

    inputValue='';
    wiredMessagesResult;
    subscription = {};
    error;
    @api recordId;
    @api fileName;
    @api fileData;
    @api fileType;
    @api channelName = '/event/NewMessage__e';
    @api offSetVal='';
    @track messages = [];
    @track contactName;
    @track isLoading = false;
    @track imageDataUrl='';
    
    connectedCallback(){
        this.handleSubscribe();
    }

    //checks whether show Send Button Enabled or Disabled
    get sendButtonClass() {
        return (this.inputValue.trim() == '' && this.imageDataUrl.trim() =='') ? true : false;
    }

    // Method to get the Messages record related to Contact
    @wire(getMessages,{ contactId: '$recordId' , offSetValFromUI : ''}) 
    messageRecs(response) {
        if (response.data) {
            this.wiredMessagesResult = response;
            this.messages = (response.data.messages);
            this.contactName = response.data.contactRecord.Name;
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
        this.imageDataUrl = '';
        console.log('In handleSendClick----');
        this.createMessageRecord();   
    }

    createMessageRecord(){
        createMessage({ messageBody: this.inputValue, contactId: this.recordId, fileName: this.fileName, fileData: this.fileData , fileType : this.fileType})
        .then(() => {
            this.inputValue = '';
            refreshApex(this.wiredMessagesResult);
        })
        .catch(error => {
            console.error(error);
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
        if (scrollContainer.scrollTop < 150 && !this.isLoading) {
            this.isLoading = true;
            let newOffSetVal = parseInt(this.offSetVal) - 5;
            getMessages({ contactId: this.recordId , offSetValFromUI : newOffSetVal})
            .then((result) => {
                this.messages = (result.messages);
                this.offSetVal = result.defaultOffSet;
                this.error = undefined;
                this.isLoading = false;
            })
            .catch((error) => {
                this.error = error;
                this.messages = undefined;
            });
        }
    }

    // Handles when any new incoming records pops up
    handleSubscribe() {
        const self = this;
        const messageCallback = function (response) {
            var obj = JSON.parse(JSON.stringify(response));
            let objData = obj.data.payload;
            if((JSON.stringify(self.recordId)).trim().replace(/"/g, '') == obj.data.payload.recordId__c){
                refreshApex(self.wiredMessagesResult);
            }    
        };
 
        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    triggerFileInput() {
        // Trigger the hidden file input
        const fileInput = this.template.querySelector('input[type="file"]');
        fileInput.click();
        console.log('In triggerFileInput');

    }

    handleFileUpload(event) {
        console.log('In handleFileUpload');
        const file = event.target.files[0];
        var reader = new FileReader();
        reader.onload = () => {
            var base64 = reader.result.split(',')[1];
            this.fileName = file.name;
            this.fileData = base64;
            this.fileType = file.fileType;
        }
        reader.readAsDataURL(file); 
        console.log('this.fileName-----',JSON.stringify(this.fileName));
        console.log('this.fileData-----',JSON.stringify(this.fileData));
        console.log('this.FileType-----',JSON.stringify(this.fileType));

        const selectedFile = event.target.files[0];
        if (selectedFile) {
            this.readFile(selectedFile);
        }

    }

    readFile(file) {
        const reader = new FileReader();

        reader.onload = (event) => {
            this.imageDataUrl = event.target.result;
        };

        reader.readAsDataURL(file);
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