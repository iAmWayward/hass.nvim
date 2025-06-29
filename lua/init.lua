return {
    setup = function(opts)
        require('neohass.config').setup(opts)
        require('neohass.commands').setup()
    end,
}
