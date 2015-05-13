/*
 * Implements a dummy match to allow attaching comments to rules
 *
 * 2003-05-13 Brad Fisher (brad@info-link.net)
 */

#include <linux/module.h>
#include <linux/skbuff.h>
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter/xt_comment.h>

MODULE_AUTHOR("Brad Fisher <brad@info-link.net>");
MODULE_DESCRIPTION("iptables comment match module");
MODULE_LICENSE("GPL");
MODULE_ALIAS("ipt_comment");
MODULE_ALIAS("ip6t_comment");

static bool
match(const struct sk_buff *skb, struct xt_action_param *par)
{
	/* We always match */
	return true;
}

static struct xt_match xt_comment_match __read_mostly = {
	.name		= "comment",
	.revision   = 0,
	.family		= AF_INET,
	.match		= match,
	.matchsize	= sizeof(struct xt_comment_info),
	.me		= THIS_MODULE
};

static int __init xt_comment_init(void)
{
	return xt_register_match(&xt_comment_match);
}

static void __exit xt_comment_fini(void)
{
	xt_unregister_match(&xt_comment_match);
}

module_init(xt_comment_init);
module_exit(xt_comment_fini);
