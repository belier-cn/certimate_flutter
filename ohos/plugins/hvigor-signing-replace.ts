import {HvigorNode, HvigorPlugin} from '@ohos/hvigor';
import {OhosAppContext, OhosPluginId} from '@ohos/hvigor-ohos-plugin';

export function signingReplacePlugin(signingConfigs : any): HvigorPlugin {
    return {
        pluginId: 'signingReplacePlugin',
        apply(node: HvigorNode) {
            node.afterNodeEvaluate(()=>{
                const appContext = node.getContext(OhosPluginId.OHOS_APP_PLUGIN) as OhosAppContext;
                const buildProfileOpt = appContext.getBuildProfileOpt();
                buildProfileOpt['app']['signingConfigs'] = signingConfigs;
                appContext.setBuildProfileOpt(buildProfileOpt);
            })
        }
    }
}