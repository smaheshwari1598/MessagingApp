import { LightningElement,track,api,wire } from 'lwc';
import getMessages from '@salesforce/apex/MessagingLWCController.getMessages';
import createMessage from '@salesforce/apex/MessagingLWCController.createMessage';

export default class MessagingLWC extends LightningElement {

    @track inputValue = '';
    @api recordId;
    messages = [];
    
    //To show or hide Send Icon Button on conditions
    get sendButtonClass() {
        return this.inputValue.trim() !== '' ? 'slds-show' : 'slds-hide';
    }

    connectedCallback() {
        this.getMessagesFromApex();
    }
    
    //Method to get Messages from Backend
    getMessagesFromApex() {
        getMessages({ contactId: this.recordId})
            .then(result => {
                this.messages = result;
            })
            .catch(error => {
                console.error(error);
            });
    }

    //Method to get the input which User Entered
    handleInputChange(event) {
        this.inputValue = event.target.value;
    }

    //Called when person Clicks on Send Icon Button
    handleSendClick() {
        createMessage({ messageBody: this.inputValue, contactId:this.recordId})
            .then(result => {
                this.messages = result;
            })
            .catch(error => {
                console.error(error);
            });
        this.inputValue = '';
    }
}