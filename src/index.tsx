import { NativeModules } from 'react-native';

interface Stickers {
  title: string;
  numColumns: number;
  list: string[];
}

export type Options = {
  path: string;
  pathId: string;
  stickers: Stickers[];
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
