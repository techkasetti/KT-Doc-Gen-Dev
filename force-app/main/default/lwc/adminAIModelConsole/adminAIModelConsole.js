import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
import saveModelConfiguration from '@salesforce/apex/AIModelManager.saveModelConfiguration';
import { refreshApex } from '@salesforce/apex';

export default class AdminAIModelConsole extends LightningElement {
    @track aiModels = [];
    @track selectedModel = null;
    @track showModelEditor = false;
    @track isLoading = false;

    wiredModelsResult;

    @wire(getAvailableAIModels)
    wiredModels(result) {
        this.wiredModelsResult = result;
        const { data, error } = result;

        if (data) {
            this.aiModels = data.map(model => ({
                ...model,
                statusIcon: model.isActive ? 'utility:success' : 'utility:clock',
                statusClass: model.isActive
                    ? 'slds-text-color_success'
                    : 'slds-text-color_weak'
            }));
        } else if (error) {
            this.showToast(
                'Error',
                'Failed to load AI models: ' + error.body.message,
                'error'
            );
        }
    }

    handleNewModel() {
        this.selectedModel = {
            modelId: '',
            modelName: '',
            provider: '',
            capabilities: '',
            isActive: false,
            endpoint: '',
            description: '',
            maxTokens: 4096,
            costPerToken: 0.002
        };
        this.showModelEditor = true;
    }

    handleEditModel(event) {
        const modelId = event.target.dataset.modelId;
        this.selectedModel = this.aiModels.find(
            model => model.modelId === modelId
        );
        this.showModelEditor = true;
    }

    handleSaveModel() {
        this.isLoading = true;
        saveModelConfiguration({ modelConfig: this.selectedModel })
            .then(() => {
                this.showToast(
                    'Success',
                    'AI Model configuration saved successfully',
                    'success'
                );
                this.showModelEditor = false;
                this.refreshModels();
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Failed to save model: ' + error.body.message,
                    'error'
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const value =
            event.target.type === 'checkbox'
                ? event.target.checked
                : event.target.value;

        this.selectedModel = {
            ...this.selectedModel,
            [field]: value
        };
    }

    refreshModels() {
        return refreshApex(this.wiredModelsResult);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
