pipelineJob('mediawiki-docker') {
    definition {
        cpsScm {
            scm {
                github('ukhc/mediawiki-docker', 'master', 'https')
            }
        }
    }
}