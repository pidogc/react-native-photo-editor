import { NativeModules } from 'react-native';
const { PhotoEditor } = NativeModules;

let exportObject = {};

const defaultOptions = {
  path: '',
  canRedo: false,
  editorModelKey: '',
  stickers: [],
};

exportObject = {
  open: (optionsEditor) => {
    const options = {
      ...defaultOptions,
      ...optionsEditor,
    };

    if (options.canRedo && !options.editorModelKey) {
      options.canRedo = false;
    }

    return new Promise(async (resolve, reject) => {
      try {
        const response = await PhotoEditor.open(options);
        if (response) {
          resolve(response);
          return true;
        }
        throw 'ERROR_UNKNOW';
      } catch (e) {
        reject(e);
      }
    });
  },
  onInitImageEditorModels: () => {
    PhotoEditor.onInitImageEditorModels();
  },
};

export default exportObject;
