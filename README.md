Stop Maxence
============

What is this?
-------------

It's a very simple client-server architecture to schedule jobs on the cluster. As we all know Maxence has an annoying tendency to spam his "super important" jobs on the cluster. On top of this he sets them high priority (obviously), with ridiculous timeouts of 10 days, without respecting the rules on the limited usage of the first node, and usually taking up a full node (i.e. 4 cores).

Since there is no way for us to make him understand what is the proper and mutually respectful way to use the cluster, we have to... **fight back**!

How do I use it?
----------------

Launch `server.rb` on any node of the cluster you want to keep off his dirty french hands, e.g.

    $ oarsub -p "network_address='<address>'" -n "Stop Maxence" -l <resources> "./server.rb"
    
Then, from your computer, you can add jobs to be scheduled on that node at any time you want, without fear that his stupid french bullshit is clogging our precious cluster:

    $ ./client.rb --addr <address> --action sched --owner <your_name> --cmdline "<your_command>" --stdout "<output_file>" --stderr "<error_file>"
    Welcome to the Stop Maxence daemon!
    Fighting back against the french army!
    Scheduled, queue size: 3

Of course you must be inside the VPN in order to access the cluster node by its IP address. When you want to check the status of the queue, use:

    $ ./client.rb --addr <address> --action list
    Welcome to the Stop Maxence daemon!
    Fighting back against the french army!
      0         User1     running       command1
      1         User2      queued       command2
      2         User3      queued       command3

Jobs are put on a FIFO queue, so each job is served after the previous one is finished.