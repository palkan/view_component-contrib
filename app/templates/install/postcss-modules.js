    generateScopedName: (name, filename, _css) => {
      const matches = filename.match(/#{ROOT_PATH.gsub('/', '\/')}\\/?(.*)\\/index.css$/);
      // Do not transform CSS files from outside of the components folder
      if (!matches) return name;

      // identifier here is the same identifier we used for Stimulus controller (see above)
      const identifier = matches[1].replace(/\\//g, "--");

      // We also add the `c-` prefix to all components classes
      return `c-${identifier}-${name}`;
    },
    // Do not generate *.css.json files (we don't use them)
    getJSON: () => {}