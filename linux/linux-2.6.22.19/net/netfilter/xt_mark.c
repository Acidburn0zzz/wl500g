/*
 *	xt_mark - Netfilter module to match NFMARK value
 *
 *	(C) 1999-2001 Marc Boucher <marc@mbsi.ca>
 *	Copyright Â© CC Computer Consultants GmbH, 2007 - 2008
 *	Jan Engelhardt <jengelh@medozas.de>
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License version 2 as
 *	published by the Free Software Foundation.
 */

#include <linux/module.h>
#include <linux/skbuff.h>

#include <linux/netfilter/xt_mark.h>
#include <linux/netfilter/x_tables.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Marc Boucher <marc@mbsi.ca>");
MODULE_DESCRIPTION("Xtables: packet mark operations");
MODULE_ALIAS("ipt_mark");
MODULE_ALIAS("ip6t_mark");
MODULE_ALIAS("ipt_MARK");
MODULE_ALIAS("ip6t_MARK");

static unsigned int
mark_tg(struct sk_buff *skb, const struct net_device *in,
		const struct net_device *out, unsigned int hooknum,
		const struct xt_target *target, const void *targinfo)
{
	const struct xt_mark_tginfo2 *info = targinfo;

	skb->mark = (skb->mark & ~info->mask) ^ info->mark;
	return XT_CONTINUE;
}

static bool
mark_mt(const struct sk_buff *skb, const struct net_device *in,
        const struct net_device *out, const struct xt_match *match,
        const void *matchinfo, int offset, unsigned int protoff, bool *hotdrop)
{
	const struct xt_mark_mtinfo1 *info = matchinfo;

	return ((skb->mark & info->mask) == info->mark) ^ info->invert;
}

static struct xt_target mark_tg_reg[] __read_mostly = {
	{
		.name           = "MARK",
		.revision       = 2,
		.family         = AF_INET,
		.target         = mark_tg,
		.targetsize     = sizeof(struct xt_mark_tginfo2),
		.me             = THIS_MODULE,
	},
	{
		.name           = "MARK",
		.revision       = 2,
		.family         = AF_INET6,
		.target         = mark_tg,
		.targetsize     = sizeof(struct xt_mark_tginfo2),
		.me             = THIS_MODULE,
	},
};

static struct xt_match mark_mt_reg[] __read_mostly = {
	{
		.name           = "mark",
		.revision       = 1,
		.family         = AF_INET,
		.match          = mark_mt,
		.matchsize      = sizeof(struct xt_mark_mtinfo1),
		.me             = THIS_MODULE,
	},
	{
		.name           = "mark",
		.revision       = 1,
		.family         = AF_INET6,
		.match          = mark_mt,
		.matchsize      = sizeof(struct xt_mark_mtinfo1),
		.me             = THIS_MODULE,
	},
};

static int __init xt_mark_init(void)
{
	int ret;

	ret = xt_register_targets(mark_tg_reg, ARRAY_SIZE(mark_tg_reg));
	if (ret < 0)
		return ret;
	ret = xt_register_matches(mark_mt_reg, ARRAY_SIZE(mark_mt_reg));
	if (ret < 0) {
		xt_unregister_targets(mark_tg_reg, ARRAY_SIZE(mark_tg_reg));
		return ret;
	}
	return 0;
}

static void __exit xt_mark_fini(void)
{
	xt_unregister_matches(mark_mt_reg, ARRAY_SIZE(mark_mt_reg));
	xt_unregister_targets(mark_tg_reg, ARRAY_SIZE(mark_tg_reg));
}

module_init(xt_mark_init);
module_exit(xt_mark_fini);
