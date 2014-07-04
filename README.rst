twitter_oauth - Send an authorized OAuth request to the Twitter REST API in Lasso 9
###################################################################################

Read the article `twitter_oauth - Send an authorized OAuth request to the
Twitter REST API in Lasso 9
<http://www.stevepiercy.com/articles/twitter_oauth-send-an-authorized-oauth-request-to-the-twitter-rest-api-in-lasso-9/>`_.

Introduction
============
Twitter frequently changes its API, authentication requirements, and its
policies. In turn developers need to adjust to the changing conditions. The
``twitter_oauth`` type is the latest iteration of playing catch-up.

Up until January 24, 2014, using Twitter from your web application was fairly
easy, thanks to Jason Huck's `twitter
<http://www.lassosoft.com/tagswap/detail/twitter>`_ custom type for Lasso 8.
It used basic authentication with a username and password. Then `Twitter shut
off basic authentication <https://dev.twitter.com/docs/auth/oauth/faq>`_ on
August 16, 2010, replacing it with OAuth. Developers were forced to use OAuth
or not use the Twitter REST API at all.

`Many other languages supported the Twitter API using OAuth
<https://dev.twitter.com/docs/twitter-libraries>`_ with their libraries, but
that meant Lasso developers would have to go through ``os_process`` or
``sys_process`` to interact with that language. No OAuth library existed for
Lasso.

Fortunately `SuperTweet <http://www.supertweet.net/>`_ provided its OAuth
proxy service for non-commercial use so that developers could continue to use
the Twitter API with only a username and password, just like old times. Jason
Huck quickly followed by updating the ``twitter`` custom type to use the
SuperTweet proxy service. But then Twitter suspended its access on January 24,
2014. If developers wanted to continue using a username and password to
interact with the Twitter API, then they had to `install their own proxy
service <http://www.supertweet.net/about/localproxy/>`_.

Prior to SuperTweet's suspension, Tim Taplin released his `oAuth_lib for lasso
<https://bitbucket.org/taplin/oauth_lib-for-lasso/>`_ on September 9, 2013.
Lasso developers now had a method to authenticate with the Twitter API using
OAuth, but implementation details were left to the developer.

A client hired me to implement those complicated details but provide a simple
interface. Among its many features, the ``twitter_oauth`` type can retrieve
recent tweets, which can be formatted using the client's own design instead of
the `widgets <https://twitter.com/settings/widgets>`_ that Twitter provides
for non-programmers.

``twitter_oauth`` is a type in Lasso 9 that allows a developer to send an
authorized OAuth request to the Twitter REST API, and returns the response in
JSON format. You can `hire me <{filename}/pages/contact.rst>`_ or `send me a
GitTip <https://www.gittip.com/stevepiercy/>`_ to create a version for Lasso
8, or you can create your own version and `contribute it to the project
<https://github.com/stevepiercy/twitter_oauth>`_. I have released the code
under a free and open source software license.

Description
===========

``twitter_oauth`` is a Lasso 9 type that allows a developer to send an
authorized OAuth request to the Twitter REST API, and returns the response in
JSON format.

Demo
====

Sorry, no demo is available at this time.

Usage
=====
Parameters
----------

``twitter_oauth`` accepts three parameters.

* ``httpmethod`` accepts a string object. It represents the HTTP method that
  shall be used in the request. Supported values are ``GET`` and ``POST``.
  This parameter is optional.
* ``baseurl`` accepts a string object. It represents the URL to which the
  request shall be sent to the Twitter REST API. Any value listed in the
  `Twitter REST API v1.1 Resources <https://dev.twitter.com/docs/api/1.1>`_ is
  supported. This parameter is optional.
* ``additional`` accepts an array object containing pairs. It represents
  additional parameters as key/value pairs that can be sent to the Twitter
  REST API. Any value pertaining to the supplied ``baseurl`` is supported. See
  `A field guide to Twitter Platform objects
  <https://dev.twitter.com/docs/platform-objects>`_ for details. This
  parameter is optional.

Methods
-------

``twitter_oauth`` has three public setter methods with names corresponding to
the three parameters listed above, and one public method to send an HTTP
request to the Twitter REST API.

* ``httpmethod`` sets the HTTP method.
* ``baseurl`` sets the base URL.
* ``additional`` sets additional parameters to send in the HTTP request.
* ``makeHTTPRequest`` makes an HTTP request to the Twitter REST API using the
  aforementioned parameters, and returns the response in JSON format.

Examples
========

.. code-block:: lasso

    // initialize the type to retrieve the three most recent tweets from
    // the user's timeline
    local(t) = twitter_oauth(
        'get',
        'https://api.twitter.com/1.1/statuses/user_timeline.json',
        array(
            'screen_name' = 'steve_piercy',
            'count' = '3',
            'exclude_replies' = 'true',
        )
    )

    // make the request, deserialize the response, and store the result
    local(r) = json_deserialize(#t->makeHTTPRequest)
    // format the response
    local(f) = string
    with i in #r do => {
        #f->append('<p>')
        #f->append(#i->find('text')->
            replace(
                regexp('(https?://\\S.+?)(\\s|$)'),
                    '<a href="\\1">\\1</a>\\2'
            )&
            replace(
                regexp('@([a-zA-Z0-9_]{1,15})'),
                '<a href="https://twitter.com/\\1">@\\1</a>'
            )&
            replace(
                regexp('#([a-zA-Z0-9_]{1,15})'),
                    '<a href="https://twitter.com/hashtag/\\1">#\\1</a>'
            )&
        )
        #f->append('</p>\n')
    }
    '<textarea>' + #f + '<textarea>'

.. code-block:: html

    =>
    <textarea>
    <p>RT <a href="https://twitter.com/iElectric">@iElectric</a>: Introducing Multi File Upload for Substance D by <a href="https://twitter.com/reebalazs">@reebalazs</a> <a href="http://t.co/N6eUoSBS4s">http://t.co/N6eUoSBS4s</a></p>
    <p>Testing new Twitter oAuth type for Lasso</p>
    <p>Pretty print JSON with <a href="https://twitter.com/BBEdit">@BBEdit</a> and Python <a href="http://t.co/EhCg67GPAV">http://t.co/EhCg67GPAV</a></p>
    </textarea>

Alternatively one could initialize a ``twitter_oauth`` object, then set its
parameters, and finally make the request.

.. code-block:: lasso

    // initialize the type
    local(t) = twitter_oauth()
    // set parameters to retrieve the three most recent tweets from the user's timeline
    #t->httpmethod = 'get'
    #t->baseurl = 'https://api.twitter.com/1.1/statuses/user_timeline.json'
    #t->additional = array(
            'screen_name' = 'steve_piercy',
            'count' = '4',
            'exclude_replies' = 'true',
        )
    // proceed with the rest of the code

Another common method is to update a user's status or send a tweet.

.. code-block:: lasso

    local(t) = twitter_oauth(
        'post',
        'https://api.twitter.com/1.1/statuses/update.json',
        array(
            'status' = 'Testing new Twitter oAuth type for Lasso'
        )
    )

Installation and Requirements
=============================

A Twitter account with a verified email address is required.

A Twitter Application is required. The `Twitter Application Management
<https://apps.twitter.com/>`_ provides developers a way to manage their
Twitter apps, including obtaining the required configuration settings to use
in the ``twitter_oauth`` type.

This type requires `sp_string_random
<https://github.com/stevepiercy/sp_string_random>`_. Download or clone its
repository.

Download or clone the `twitter_oauth
<https://github.com/stevepiercy/twitter_oauth>`_ type.

Edit the file ``twitter_oauth.lasso`` to use your Twitter Application
configuration settings, and save.

Install both files ``sp_string_random.lasso`` and ``twitter_oauth.lasso``
where you think is best. Either place it in your Lasso Server's or Instances's
``LassoStartup`` directory, restarting the appropriate scope as needed. I
recommend Lasso Instance ``LassoStartup``.

Notes
=====

The project `twitter_oauth <https://github.com/stevepiercy/twitter_oauth>`_
and its source files are hosted on GitHub.

`Twitter REST API v1.1 Resources <https://dev.twitter.com/docs/api/1.1>`_

`A field guide to Twitter Platform objects <https://dev.twitter.com/docs/platform-objects>`_

`Exploring the Twitter API <https://dev.twitter.com/console>`_ with an online
API tester.

While writing this type, I referred a great deal to Twitter API documentation
on `Creating a signature
<https://dev.twitter.com/docs/auth/creating-signature>`_ and `Authorizing a
request <https://dev.twitter.com/docs/auth/authorizing-request>`_.
