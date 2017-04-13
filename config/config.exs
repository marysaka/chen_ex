[
  pooler: [
    pools: [
     [
        name: :riaklocal,
        group: :riak,
        max_count: 15,
        init_count: 2,
        start_mfa: { Riak.Connection, :start_link, ['127.0.0.1', 7087] }
      ]
    ]
  ],
  chen_ex: [
    domain: "192.168.1.25",
    base_url: "http://192.168.1.25:4242"
  ]
]
