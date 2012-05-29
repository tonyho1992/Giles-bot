require 'logger'
require 'github_api'

# This is a complete hack. blather/client monkeypatches a query method into String. This cases github_api to fail
# To prevent this from happening, I monkeypatched the module Faraday Request function so that it will never respond
# to a query function
module Faraday
    class Request
        # < Struct.new(:method, :path, :params, :headers, :body, options)
        # extend AutoloadHelper
        # extend MiddlewareRegistry

        def url(path, params = null)
            # This is the hacky line. Might need to be object type of String, but I can change that later
            if path.respond_to? :query and false
                if query = path.query
                    path = path.dup
                    path.query = nill
                end    
            else
                path, query = path.split('?', 2)
            end
            self.path = path
            self.params.merge_query query
            self.params.update(params) if params
        end
    end
end

module Bot
    class Giles
        def initialize(login, password)
            @login  = login
            @password  = password
            @log       = Logger.new(STDOUT)
            @log.level = Logger::DEBUG
            @github = Github.new basic_auth: @login + ":" + @password
        end

        def buildMessage(user, body) 
            return Blather::Stanza::Message.new user, body
        end

        def onStatus(fromNodeName)
            # Dont do anything on status
            return []
        end

        def handleRepos(requester)
            repos = (@github.repos.all.map { |repo| repo.name }).sort
            return [(buildMessage requester, ("Giles: Here are your current repositories: " + repos.join(", ")))]
        end

        def handleCommits(requester, repo)
            commits_raw = @github.repos.commits.all @login, repo
            commits = commits_raw.map { |commit_data| commit_data.commit["message"] }
            return [(buildMessage requester, ("Giles: Here are your current commits for " + repo + ": " + commits.join(", ")))]
        end

        def handleBranches(requester, repo)
            branches_raw = @github.repos.branches @login, repo
            branches = branches_raw.map { |branch| branch.name }
            return [(buildMessage requester, ("Giles: Here are your current branches for " + repo + ": " + branches.join(", ")))]
        end

        def handlePullRequests(requester, repo)
            prs_raw = @github.pull_requests.all @login, repo
            prs = prs_raw.map { |pr| pr.title }
            return [(buildMessage requester, ("Giles: Here are your current pullRequests for " + repo + ": " + prs.join(", ")))]
        end

        def handleIssues(requester, repo)
            iss_raw = @github.issues.list_repo @login, repo
            iss = iss_raw.map { |is| is.title }
            return [(buildMessage requester, ("Giles: Here are your current issues for " + repo + ": " + iss.join(", ")))]
        end

        def getRepo(queryText)
            words = queryText.split(" ")
            index = words.rindex("in")
            return words[index + 1] if index
            return index
        end

        def onQuery(message)
            senderName = message.from.node.to_s
            sender = message.from.stripped
            queryText = message.body

            repo = getRepo queryText

            # Global
            if queryText.match /repo/i
                @log.debug "[Giles]: Retrieving Repositories"

                yield (buildMessage sender, "Giles: Working on your repositories...")

                return handleRepos sender
            elsif queryText.match /commit/i and repo
                @log.debug "[Giles]: Retrieving Repositories"

                yield (buildMessage sender, "Giles: Working on your commits...")

                return handleCommits sender, repo
            elsif queryText.match /branch/i and repo
                yield (buildMessage sender, "Giles: Working on your branches...")

                return handleBranches sender, repo
            elsif queryText.match /pull request/i and repo
                yield (buildMessage sender, "Giles: Working on your pull requests...")

                return handlePullRequests sender, repo
            elsif queryText.match /issue/i and repo
                yield (buildMessage sender, "Giles: Working on your issues...")

                return handleIssues sender, repo
            elsif queryText.match /hey/i or queryText.match /hello/i
                # Just a greeting
                return [(buildMessage sender, ("Giles: Hello "+senderName))]
            end

             # Default / Give up
             return [(buildMessage sender, ("Giles: Sorry "+senderName+", I can't help you with that."))]
        end

        def onMessage(message, &onProgress)
            # Query handling
            queryMsgs = []
            if message.body.match /giles/ or message.body.match /Giles/
                queryMsgs = onQuery message, &onProgress
            end

            return queryMsgs
        end

    end
end
