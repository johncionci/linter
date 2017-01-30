exports.config = {
	files: {
		javascripts: {
			joinTo: {
				"js/main.js": /^(src\/js)/,
				"js/vendor.js": /^(bower_components)/
			}
		},
		stylesheets: {
			joinTo: "css/styles.css"
		},
	},
	paths: {
		watched: [
			"src/scss/",
			"src/js/"
		],
		public: "web/app/themes/pre-commit-linter/assets"
	},
	plugins: {
		babel: {
			ignore: [/^(bower_components)/],
			pattern: /\.(js|jsx)/
		},
		browserSync: {
			host: "192.168.56.101",
			proxy: "pre-commit-linter.dev",
			files: ["web/app/themes/pre-commit-linter/assets/css/*.css", "web/app/themes/pre-commit-linter/assets/js/*.js"]
		}
	},
	modules: {
		nameCleaner: function (path) {
			return path.replace(/src\/js\//, '');
		}
	}
};
