/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run "npm run dev" in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run "npm run deploy" to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */


export default {
    async fetch(request, env, ctx) {
      return await callOpenai(request, env)
    }
  }
  
  function auth(request) {
    let token = request.headers.get('Authorization')
    if (token) {
      token = token.replace('Bearer ', '')
      if (token == CF_TOKEN) {
        return true
      }
    }
    return false
  }
  
  // async function saveKV(table, key, value){
  //   if(null!=value){
  //       if("object"==typeof value){
  //           value=JSON.stringify(value)
  //       }
  //       await table.put(key,value)
  //       return true
  //   }
  //   return false;
  // }
  
  async function procFeedback(feedback, udid, timestamp, env) {
    console.log('procFeedback', feedback, 'udid', udid)
    await env.kv_quotes_feedback.put(new Date().getTime(), feedback)
    // await saveKV(kv_quotes_feedback, new Date().getTime(), feedback)
    return new Response('feedback received');
  }
  
  async function getQuote(infoObj, wishStr, udid, timestamp, env) {
    // console.log('wishStr', wishStr, 'udid', udid)
    let userPrompt = 'My thoughts: ' + wishStr
    let quotesHist = {}
    let quotesHistStr = ''
    let systemPrompt = 'Based on the thoughts of the user, give 3 quotes. Max 20 words each quote.'
    if (udid) {
      // systemPrompt += 'Strictly follow the json format: [{\"quote\":..., \"author\":...}, {\"quote\":..., \"author\":...}, ...]. AVOID giving quotes you have given in previous conversations. Give different quotes every time.'
      systemPrompt += 'Strictly follow the json format: [{\"quote\":..., \"author\":...}, {\"quote\":..., \"author\":...}, ...]. '
      systemPrompt += 'Based on the history answer list (only beginning of quotes shown), AVOID answers similar to any quote in that list. '
  
    if (infoObj.reqHist) {
      if (infoObj.reqHist[wishStr]) {
        quotesHist = infoObj.reqHist[wishStr]
        // get the first 20 characters after each quote, and put all in an array
        // read only the most recent ones
        let quotesHistShort = []
        const histLimit = 15
        let keys = Object.keys(quotesHist).sort((a, b) => {
            return new Date(b) - new Date(a)
        })
        // console.log(keys)
        for (let i = 0; i < keys.length; i++) {
            let key = keys[i]
            quotesHist[key].forEach((quote) => {
              quotesHistShort.push('\"' + quote.quote.slice(0, 20) + '\"' /*+ '-' + quote.author*/)
            })
            if (quotesHistShort.length > histLimit) {
                break
            }
        }
        let quotesHistConcat = '[' + quotesHistShort.join(', ') + ']'
        // console.log(quotesHistShort);
        // userPrompt += '. AVOID giving the following quotes (truncated to only the beginnings) that you have given in previous conversations: ' + quotesHistConcat
        // userPrompt += '. AVOID answers containing substrings in the following list: ' + quotesHistConcat
        userPrompt += '. History answer list: ' + quotesHistConcat
      }
    } else {
      infoObj.reqHist = {}
    }
    } else {
      systemPrompt += 'Strictly follow format: quote | author (new line) quote | author.'
    }
    console.log('systemPrompt', systemPrompt)
    console.log('userPrompt', userPrompt)
  
    const reqBody = {
      'model': 'gpt-3.5-turbo-1106',
      'messages': [{
        'role': 'system',
        'content': systemPrompt
      },
      {
        'role': 'user',
        'content': userPrompt
      }],
      'temperature': 1
    }
  
    // 定义目标服务器的地址
    const targetUrl = 'https://api.openai.com/v1/chat/completions'
  
    // 构造新的请求对象
    const proxyRequest = new Request(targetUrl, {
      method: 'POST',
      headers: { 'Authorization': 'OPENAI_TOKEN', 'content-type': 'application/json' },
      body: JSON.stringify(reqBody) //request.body 
    })
  
    // 发送请求到目标服务器
    console.log('sending openai request', (new Date()).toISOString())
    const response = await fetch(proxyRequest)
    console.log('received openai request', (new Date()).toISOString())
  
    let proxyResponse = new Response('no quote')
    if (udid) {
      const answer = await response.json()
      console.log('answer', answer)
  
      if (answer.choices && answer.choices.length > 0 && 
        answer.choices[0].message && answer.choices[0].message.content) {
        let quotesNew = answer.choices[0].message.content
        console.log('quotes content', quotesNew)
        const quotesNewObj = JSON.parse(quotesNew)
        quotesHist[timestamp] = quotesNewObj
        infoObj.reqHist[wishStr] = quotesHist
        await putInfoObj(infoObj, udid, env)
  
        proxyResponse = new Response(quotesNew)
      }
    } else {
      await env.kv_quotes_requests.put(new Date().getTime(), wishStr)
      // 构造新的响应对象
      proxyResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers
      })
    }
    console.log('getQuotes finished', (new Date()).toISOString())
  
    
    return proxyResponse
  }
  
  async function getInfoObj(request, udid, env) {
    let info = await env.kv_quotes_requests3.get(udid);
    let infoObj = {}
    if (info !== null) {
      infoObj = JSON.parse(info)
    }
    if (!infoObj.city) {
      infoObj.city = request.cf['city']
    }
    if (!infoObj.country) {
      infoObj.country = request.headers.get('cf-ipcountry')
    }
    // console.log('getInfoObj', infoObj)
    return infoObj
  }
  
  async function putInfoObj(infoObj, udid, env) {
    const info = JSON.stringify(infoObj);
    // console.log('putInfoObj', info)
    return await env.kv_quotes_requests3.put(udid, info)
  }
  
  async function procWidgetStatus(infoObj, widgetStatus, udid, timestamp, env) {
    // console.log('widgetStatus', widgetStatus, 'udid', udid)
    
    const widgetStr = widgetStatus + '_' + timestamp
    if (infoObj['widget']){
      infoObj.widget.push(widgetStr)
    } else {
      infoObj.widget = [widgetStr]
    }
    await putInfoObj(infoObj, udid, env)
    return new Response('widgetStatus received');
  }
  
  async function logAction(infoObj, bodyStr, udid, timestamp, env) {
    const actionList = ['firstStart', 'enteredMainUI', 'enteredThoughts', 'addedOwn']
    for (let i = 0; i < actionList.length; i++) {
      const action = actionList[i]
      if (bodyStr.hasOwnProperty(action)) {
        const actionObj = {[timestamp]: {[action]: bodyStr[action]}}
        // console.log('actionObj', actionObj)
        if (infoObj['actions']) {
          infoObj['actions'].push(actionObj)
        } else {
          infoObj['actions'] = [actionObj]
        }
        // console.log('infoObj', infoObj)
        await putInfoObj(infoObj, udid, env)
        return
      }
    }
  }
  
  async function procRequest(request, env) {
    const bodyStr = await request.json()
    console.log('New request: ', bodyStr)
    const udid = bodyStr['udid']
    const timestamp = (new Date()).toISOString().slice(0, -5)
    let infoObj = await getInfoObj(request, udid, env)
  
    const feedback = bodyStr['feedback']
    let resp = new Response('request done');
    if (feedback) {
      resp = await procFeedback(feedback, udid, timestamp, env) 
    }
    const wishStr = bodyStr['wishStr']
    if (wishStr) {
      resp = await getQuote(infoObj, wishStr, udid, timestamp, env)
    }
    const widgetStatus = bodyStr['widgetStatus']
    if (widgetStatus) {
      resp = await procWidgetStatus(infoObj, widgetStatus, udid, timestamp, env)
    }
    await logAction(infoObj, bodyStr, udid, timestamp, env)
    console.log('response finished', (new Date()).toISOString())
    return resp
  }
  
  async function callOpenai(request, env) {
    console.log('request received', (new Date()).toISOString())
    if (!auth(request)) {
      return new Response('invalid');
    }
  
    const proxyResponse = await procRequest(request, env)
  
    // 返回响应给客户端
    return proxyResponse
  }
  
