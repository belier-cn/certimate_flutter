import path from 'path'
import {appTasks} from '@ohos/hvigor-ohos-plugin';
import {flutterHvigorPlugin} from 'flutter-hvigor-plugin';
import {signingReplacePlugin} from './plugins/hvigor-signing-replace';
import signingConfigs from "./signing-configs.json";

export default {
    system: appTasks,
    plugins: [signingReplacePlugin(signingConfigs), flutterHvigorPlugin(path.dirname(__dirname))]
}