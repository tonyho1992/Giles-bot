require 'logger'
require 'blather/stanza/message'
require 'github_api'

module Bot
    class Giles
        def initialize(username, repo)
            @username  = username
            @repo      = repo
            @log       = Logger.new(STDOUT)
            @log.level = Logger::DEBUG
        end

        def buildMessage(user, body) 
            return Blather::Stanza::Message.new user, body
        end

        def onStatus(fromNodeName)
            # Dont do anything on status
            return []
        end

        def onQuery(message)
            senderName = message.from.node.to_s
            sender = message.from.stripped

            @log.debug "[Giles]: " + @username + "/" + @repo

            github = Github.new

            # TODO handle Github queries

            # Global
            if message.body.match /hey/ or message.body.match /hello/
                # Just a greeting
                return [buildMessage sender, "Giles: Hello "+senderName]
            else
                # Default / Give up
                return [buildMessage sender, "Giles: Sorry "+senderName+", I can't help you with that."]
            end

        end

        def onMessage(message)
            # Query handling
            queryMsgs = []
            if message.body.match /giles/ or message.body.match /Giles/
                queryMsgs = onQuery(message)
            end

            return queryMsgs
        end

    end
end