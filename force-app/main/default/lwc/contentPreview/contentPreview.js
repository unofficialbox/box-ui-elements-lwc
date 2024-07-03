import { LightningElement, api } from 'lwc';
import downscopeToken from '@salesforce/apex/BoxPreviewController.downscopeToken';

export default class ContentPreview extends LightningElement {
    @api elementTitle;
    @api height;
    @api fileId;
    @api scopes;
    @api buieURL;
    @api downscopedToken;

    error;

    connectedCallback() {    
        // Call apex method to get downscoped token
        downscopeToken({
            fileId: this.fileId,
            scopes: this.scopes,
        })
        .then(responseMap => {
            this.fileId = responseMap.fileId;
            this.downscopedToken = responseMap.accessToken;      
            const ltnOrigin = responseMap.ltnOrigin;
            console.log('Found ltn origin: ', ltnOrigin);

            // Set the buieURL used in the iframe src param
            this.buieURL = `${ltnOrigin}/apex/ContentPreview?fileId=${this.fileId}&downscopedToken=${this.downscopedToken}&height=${this.height}`;
        })
        .catch(error => {
            this.error = error;
            console.log('Found error: ', error);
        });
    }
}