import { NativeModules } from 'react-native';

export type Options = {
  path: string;
  pathId: string;
  stickers: Array<string>;
};

export type ErrorCode =
  | 'USER_CANCELLED'
  | 'IMAGE_LOAD_FAILED'
  | 'ACTIVITY_DOES_NOT_EXIST'
  | 'FAILED_TO_SAVE_IMAGE'
  | 'DONT_FIND_IMAGE'
  | 'ERROR_UNKNOW'
  | 'DONT_FIND_PATHID';

type PhotoEditorType = {
  open(option: Options): Promise<string>;
  onInitImageEditorModels(): void;
};

const { PhotoEditor } = NativeModules;

export default PhotoEditor as PhotoEditorType;
