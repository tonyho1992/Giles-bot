require 'logger'
require 'blather/stanza/message'
require 'github_api'

module Bot
    class Giles
        def initialize(username, password)
            @username  = username
            @password  = password
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

        def handleRepos(requester)
            repos = @github.repos.all.map { |repo| repo.name }
            return [(buildMessage requester, ("Giles: Here are you current repositories: " + repos.join(", ")))]
        end

        def handleCommits(requester)
            repo = "Giles-bot"
            commits_raw = @github.repos.commits.all "tonyho1992", repo
            commits = commits_raw.map { |commit_data| commit_data.commit.message }
            return [(buildMessage requester, ("Giles: Here are you current commits for " + repo + ": " + commits.join(", ")))]
        end

        def onQuery(message)
            senderName = message.from.node.to_s
            sender = message.from.stripped
            queryText = message.body

            # TODO Parse the following
            # Repo - "on repo"
            # Commits - "commits / all commits" / "last commit"
            # Branch - "on branch"
            # Issues - "all"
            # look into hooks

            @github = Github.new basic_auth: @username + ":" + @password

            # Global
            if queryText.match /repo/i
                @log.debug "[Giles]: Retrieving Repositories"

                # yield (buildMessage sender, "Giles: Working on your repositories...")

                return handleRepos sender
            elsif queryText.match /commit/i
                @log.debug "[Giles]: Retrieving Repositories"

                yield (buildMessage sender, "Giles: Working on your commits...")

                return handleCommits sender
            elsif queryText.match /branch/i
                yield (buildMessage sender, "Giles: Working on your branches...")
                return handleBranches sender
            elsif queryText.match /pull request/i
                yield (buildMessage sender, "Giles: Working on your pull requests...")
                return handlePullRequests sender
            elsif queryText.match /hook/i
                yield (buildMessage sender, "Giles: Working on your hooks...")
                return handleHookRequests sender
            elsif queryText.match /hey/i or queryText.match /hello/i
                # Just a greeting
                return [(buildMessage sender, ("Giles: Hello "+senderName))]
            else
                # Default / Give up
                return [(buildMessage sender, ("Giles: Sorry "+senderName+", I can't help you with that."))]
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