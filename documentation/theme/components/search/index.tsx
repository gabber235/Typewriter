// theme/index.tsx
import { Search as PluginAlgoliaSearch } from '@rspress/plugin-algolia/runtime';

const Search = () => {
  return (
    <PluginAlgoliaSearch
      docSearchProps={{
        appId: 'GE6F02MN59',
        apiKey: '57ae467d6c3f66ac2cae2c98e4275f49',
        indexName: 'typewriter',
      }}
    />
  );
};
export { Search };
export * from '@rspress/core/theme-original';