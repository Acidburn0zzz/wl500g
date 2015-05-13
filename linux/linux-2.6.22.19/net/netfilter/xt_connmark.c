/*
 *	xt_connmark - Netfilter module to operate on connection marks
 *
 *	Copyright (C) 2002,2004 MARA Systems AB <http://www.marasystems.com>
 *	by Henrik Nordstrom <hno@marasystems.com>
 *	Copyright Â© CC Computer Consultants GmbH, 2007 - 2008
 *	Jan Engelhardt <jengelh@computergmbh.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <linux/module.h>
#include <linux/skbuff.h>
#include <net/netfilter/nf_conntrack.h>
#include <net/netfilter/nf_conntrack_ecache.h>
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter/xt_connmark.h>

MODULE_AUTHOR("Henrik Nordstrom <hno@marasytems.com>");
MODULE_DESCRIPTION("Xtables: connection mark operations");
MODULE_LICENSE("GPL");
MODULE_ALIAS("ipt_CONNMARK");
MODULE_ALIAS("ip6t_CONNMARK");
MODULE_ALIAS("ipt_connmark");
MODULE_ALIAS("ip6t_connmark");

static unsigned int
connmark_tg(struct sk_buff *skb, const struct net_device *in,
			   const struct net_device *out, unsigned int hooknum,
			   const struct xt_target *target,
			   const void *targinfo)
{
	const struct xt_connmark_tginfo1 *info = targinfo;
	enum ip_conntrack_info ctinfo;
	struct nf_conn *ct;
	u_int32_t newmark;

	ct = nf_ct_get(skb, &ctinfo);
	if (ct == NULL)
		return XT_CONTINUE;

	switch (info->mode) {
	case XT_CONNMARK_SET:
		newmark = (ct->mark & ~info->ctmask) ^ info->ctmark;
		if (ct->mark != newmark) {
			ct->mark = newmark;
			nf_conntrack_event_cache(IPCT_MARK, skb);
		}
		break;
	case XT_CONNMARK_SET_RETURN:
		// Set connmark and mark, apply mask to mark, do XT_RETURN	- tomato
		newmark = ct->mark = info->ctmark;
		newmark &= info->ctmask;
		if (newmark != skb->mark) {
			skb->mark = newmark;
		}
		return XT_RETURN;
	case XT_CONNMARK_SAVE:
		newmark = (ct->mark & ~info->ctmask) ^
		          (skb->mark & info->nfmask);
		if (ct->mark != newmark) {
			ct->mark = newmark;
			nf_conntrack_event_cache(IPCT_MARK, skb);
		}
		break;
	case XT_CONNMARK_RESTORE:
		newmark = (skb->mark & ~info->nfmask) ^
		          (ct->mark & info->ctmask);
		skb->mark = newmark;
		break;
	}

	return XT_CONTINUE;
}

static bool connmark_tg_check(const char *tablename, const void *entry,
		      const struct xt_target *target, void *targinfo,
		      unsigned int hook_mask)
{
	if (nf_ct_l3proto_try_module_get(target->family) < 0) {
		printk(KERN_WARNING "cannot load conntrack support for "
		       "proto=%u\n", target->family);
		return false;
	}
	return true;
}

static void connmark_tg_destroy(const struct xt_target *target, void *targinfo)
{
	nf_ct_l3proto_module_put(target->family);
}

static bool
connmark_mt(const struct sk_buff *skb,
      const struct net_device *in,
      const struct net_device *out,
      const struct xt_match *match,
      const void *matchinfo,
      int offset,
      unsigned int protoff,
      int *hotdrop)
{
	const struct xt_connmark_mtinfo1 *info = matchinfo;
	enum ip_conntrack_info ctinfo;
	const struct nf_conn *ct;

	ct = nf_ct_get(skb, &ctinfo);
	if (ct == NULL)
		return false;

	return ((ct->mark & info->mask) == info->mark) ^ info->invert;
}

static bool
connmark_mt_check(const char *tablename, const void *ip,
                  const struct xt_match *match, void *matchinfo,
                  unsigned int hook_mask)
{
	if (nf_ct_l3proto_try_module_get(match->family) < 0) {
		printk(KERN_WARNING "cannot load conntrack support for "
		       "proto=%u\n", match->family);
		return 0;
	}
	return 1;
}

static void
destroy(const struct xt_match *match, void *matchinfo)
{
	nf_ct_l3proto_module_put(match->family);
}

static struct xt_target connmark_tg_reg __read_mostly = {
	.name           = "CONNMARK",
	.revision       = 1,
	.family         = NFPROTO_UNSPEC,
	.checkentry     = connmark_tg_check,
	.target         = connmark_tg,
	.targetsize     = sizeof(struct xt_connmark_tginfo1),
	.destroy        = connmark_tg_destroy,
	.me             = THIS_MODULE,
};

static struct xt_match xt_connmark_match __read_mostly = {
	.name           = "connmark",
	.revision       = 1,
	.family         = NFPROTO_UNSPEC,
	.checkentry     = connmark_mt_check,
	.match          = connmark_mt,
	.matchsize      = sizeof(struct xt_connmark_mtinfo1),
	.destroy        = destroy,
	.me             = THIS_MODULE,
};

static int __init xt_connmark_init(void)
{
	int ret;

	ret = xt_register_target(&connmark_tg_reg);
	if (ret < 0)
		return ret;
	ret = xt_register_match(&xt_connmark_match);
	if (ret < 0) {
		xt_unregister_target(&connmark_tg_reg);
		return ret;
	}
	return 0;
}

static void __exit xt_connmark_fini(void)
{
	xt_unregister_match(&xt_connmark_match);
	xt_unregister_target(&connmark_tg_reg);
}

module_init(xt_connmark_init);
module_exit(xt_connmark_fini);
