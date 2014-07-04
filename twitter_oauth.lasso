[
// https://github.com/stevepiercy/twitter_oauth
// this type requires sp_string_random
// https://github.com/stevepiercy/sp_string_random
define twitter_oauth => type {
    data
        public httpmethod::string = '',
        public baseurl::string = '',
        public additional::array=array,
        private oauth_params::array=array,
        private oauth_authorization_header = '',
        // To configure, obtain settings through https://dev.twitter.com/apps
        // configure = API key
        private oauth_consumer_key = 'xxxxxxxxxxxxxxxxxxxx',
        // configure = API secret
        private oauth_consumer_secret = 'xxxxxxxxxxxxxxxxxxxx',
        // generated for each request
        private oauth_nonce = sp_string_random(32),
        private oauth_signature = '',
        // Twitter requirement
        private oauth_signature_method = 'HMAC-SHA1',
        private oauth_timestamp = date->asinteger,
        // configure = Access token
        private oauth_token = 'xxxxxxxxxxxxxxxxxxxx',
        // configure = Access token secret
        private oauth_token_secret = 'xxxxxxxxxxxxxxxxxxxx',
        // Twitter requirement
        private oauth_version = '1.0'

    private onCreate() => {
        .'oauth_params' = array(
            'oauth_consumer_key' = .'oauth_consumer_key',
            'oauth_nonce' = .'oauth_nonce',
            'oauth_signature_method' = .'oauth_signature_method',
            'oauth_timestamp' = .'oauth_timestamp',
            'oauth_token' = .'oauth_token',
            'oauth_version' = .'oauth_version'
            )
    }

    private onCreate(httpmethod, baseurl, additional) => {
        // check to ensure there are no duplicate additional parameters
        // see note [2] https://dev.twitter.com/docs/auth/creating-signature#note-sorting
        local(s) = set
        with x in #additional do => {
            #s->insert(#x)
        }
        fail_if(#additional->size != #s->size, 'Duplicate additional parameters are not permitted.')
        // proceed by setting data members
        .'additional' = #additional
        .'httpmethod' = string(#httpmethod)
        .'baseurl' = string(#baseurl)
        .'oauth_params' = array(
            'oauth_consumer_key' = .'oauth_consumer_key',
            'oauth_nonce' = .'oauth_nonce',
            'oauth_signature_method' = .'oauth_signature_method',
            'oauth_timestamp' = .'oauth_timestamp',
            'oauth_token' = .'oauth_token',
            'oauth_version' = .'oauth_version'
            )
    }
 
    // override setters
    public httpmethod=(v) => {
        .'httpmethod' = #v
        return .'httpmethod'
    }
    public baseurl=(v) => {
        .'baseurl' = #v
        return .'baseurl'
    }
    public additional=(v) => {
        // check to ensure there are no duplicate additional parameters
        // see note [2] https://dev.twitter.com/docs/auth/creating-signature#note-sorting
        local(s) = set
        with x in #v do => {
            #s->insert(#x)
        }
        fail_if(#v->size != #s->size, 'Duplicate additional parameters are not permitted.')
        .'additional' = #v
        return .'additional'
    }
    
    // Encoded parameter string
    // See "Collecting parameters" at:
    // https://dev.twitter.com/docs/auth/creating-signature
    private encodedParameterString() => {
        local(t1) = .'oauth_params'->ascopy
        local(t2) = array
        local(eps) = string
        #t1->merge(.'additional')
        with p in #t1 do => {
            #t2->insert(encode_stricturl(#p->first->asstring) = encode_stricturl(#p->second->asstring))
        }
        #t2->sort
        with p in #t2 do => {
            #eps->append(#p->first + '=' #p->second + '&')
        }
        #eps->removetrailing('&')
        return(#eps)
    }

    // Signature Base String
    // See "Creating the signature base string" at:
    // https://dev.twitter.com/docs/auth/creating-signature
    private signatureBaseString() => {
        local(sbs) = string
        #sbs->append(string_uppercase(.'httpmethod'))
        #sbs->append('&')
        #sbs->append(encode_stricturl(.'baseurl'))
        #sbs->append('&')
        #sbs->append(encode_stricturl(.encodedParameterString))
        return(#sbs)
    }
 
    // Get Signing Key
    // See "Getting a signing key" at:
    // https://dev.twitter.com/docs/auth/creating-signature
    private getSigningKey() => {
        local(gsk) = string
        #gsk->append(encode_stricturl(.'oauth_consumer_secret'))
        #gsk->append('&')
        #gsk->append(encode_stricturl(.'oauth_token_secret'))
        return(#gsk)
    }

    // Calculate Signature
    // See "Calculating the signature" at:
    // https://dev.twitter.com/docs/auth/creating-signature
    private calculateSignature() => {
        local(cs) = string
        #cs = encrypt_hmac(
            -password=(.getSigningKey),
            -token=(.signatureBaseString),
            -digest='SHA1',
            -base64
            )
        .'oauth_signature' = #cs
    }

    // Build an authorizing header string to be used with the request
    // See "Building the header string" at:
    // https://dev.twitter.com/docs/auth/authorizing-request
    private buildAuthorizationHeader() => {
        .calculateSignature()
        local(bhs) = string
        #bhs->append('OAuth ')
        local(t1) = .'oauth_params'->ascopy
        #t1->insert('oauth_signature' = .'oauth_signature')
        #t1->sort
        with p in #t1 do => {
            #bhs->append(encode_stricturl(#p->first->asstring))
            #bhs->append('=')
            #bhs->append('"')
            #bhs->append(encode_stricturl(#p->second->asstring))
            #bhs->append('", ')
        }
        #bhs->removetrailing(', ')
        .'oauth_authorization_header' = #bhs
    }

    // make the request, return the response
    public makeHTTPRequest => {
        .buildAuthorizationHeader()
        local(r)
        match(string_uppercase(.'httpmethod')) => {
            case('GET')
                #r = include_url(
                    .'baseurl',
                    -getparams=.'additional',
                    -sendmimeheaders = array('Authorization' =    .'oauth_authorization_header'))
            case('POST')
                #r = include_url(
                    .'baseurl',
                    -postparams=.'additional',
                    -sendmimeheaders = array('Authorization' =    .'oauth_authorization_header'))
            case()
                #r = 'Supplied httpmethod not implemented.'
        }
        return(#r)
    }
}
]
